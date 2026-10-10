-- Diff-Dark — card de sistema (anéis de CPU/RAM/disco) desenhado em Cairo.
-- no AppImage o cpath aponta pro diretório de build; os bindings ficam em $APPDIR
local appdir = os.getenv('APPDIR')
if appdir then package.cpath = appdir .. '/usr/lib/conky/lib?.so;' .. package.cpath end
require 'cairo'
pcall(require, 'cairo_xlib')

local C = {
  ink2    = {0xdc, 0xdf, 0xdd},
  muted   = {0x85, 0x8b, 0x88},
  dim     = {0x4e, 0x53, 0x51},
  track   = {0x2a, 0x2d, 0x2c},
  card    = {0x16, 0x18, 0x17},
  edge    = {0x2a, 0x2d, 0x2c},
  sage    = {0x8f, 0xb3, 0x9d},
  grey    = {0xbf, 0xc3, 0xc1},
}

local UI_FONT = 'Inter'

local function rgba(cr, c, a)
  cairo_set_source_rgba(cr, c[1] / 255, c[2] / 255, c[3] / 255, a or 1)
end

local function font(cr, face, size, bold)
  cairo_select_font_face(cr, face, CAIRO_FONT_SLANT_NORMAL,
    bold and CAIRO_FONT_WEIGHT_BOLD or CAIRO_FONT_WEIGHT_NORMAL)
  cairo_set_font_size(cr, size)
end

local function text_width(cr, s)
  local ext = cairo_text_extents_t:create()
  tolua.takeownership(ext)
  cairo_text_extents(cr, s, ext)
  return ext.x_advance
end

-- align: 'left' | 'right' | 'center'
local function text(cr, s, x, y, align)
  local w = text_width(cr, s)
  if align == 'right' then x = x - w elseif align == 'center' then x = x - w / 2 end
  cairo_move_to(cr, x, y)
  cairo_show_text(cr, s)
  return x + w
end

local function rounded_rect(cr, x, y, w, h, r)
  cairo_new_path(cr)
  cairo_arc(cr, x + w - r, y + r, r, -math.pi / 2, 0)
  cairo_arc(cr, x + w - r, y + h - r, r, 0, math.pi / 2)
  cairo_arc(cr, x + r, y + h - r, r, math.pi / 2, math.pi)
  cairo_arc(cr, x + r, y + r, r, math.pi, 3 * math.pi / 2)
  cairo_close_path(cr)
end

local function card(cr, x, y, w, h)
  rounded_rect(cr, x, y, w, h, 16)
  rgba(cr, C.card, 0.72)
  cairo_fill_preserve(cr)
  cairo_set_line_width(cr, 1)
  rgba(cr, C.edge, 0.9)
  cairo_stroke(cr)
end

local function ring(cr, cx, cy, r, pct, color, label)
  local start = -math.pi / 2
  cairo_set_line_width(cr, 5)
  cairo_set_line_cap(cr, CAIRO_LINE_CAP_ROUND)
  rgba(cr, C.track, 1)
  cairo_new_path(cr)
  cairo_arc(cr, cx, cy, r, 0, 2 * math.pi)
  cairo_stroke(cr)
  if pct > 0 then
    rgba(cr, color, 1)
    cairo_new_path(cr)
    cairo_arc(cr, cx, cy, r, start, start + 2 * math.pi * math.min(pct, 100) / 100)
    cairo_stroke(cr)
  end
  font(cr, UI_FONT, 13, true); rgba(cr, C.ink2)
  text(cr, string.format('%d%%', pct), cx, cy + 5, 'center')
  font(cr, UI_FONT, 10.5); rgba(cr, C.muted)
  text(cr, label, cx, cy + r + 24, 'center')
end

local function num(expr)
  return tonumber(conky_parse(expr)) or 0
end

local function with_surface(fn)
  if conky_window == nil then return end
  local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable,
    conky_window.visual, conky_window.width, conky_window.height)
  local cr = cairo_create(cs)
  cairo_set_antialias(cr, CAIRO_ANTIALIAS_BEST)
  fn(cr, conky_window.width)
  cairo_destroy(cr)
  cairo_surface_destroy(cs)
end

-- Salva a posição da janela quando ela é arrastada, pra nascer no mesmo
-- lugar no próximo start. Checa a cada 3s; só escreve quando muda.
-- A primeira checagem espera 3s pra o place.py já ter posicionado a janela:
-- assim a posição de nascimento não é confundida com um arraste.
local POS_FILE = os.getenv('HOME') .. '/.local/share/diff-dark/stats-pos'
local last_check, last_pos = os.time(), nil

local function remember_position()
  local now = os.time()
  if now - last_check < 3 then return end
  last_check = now
  local p = io.popen('xwininfo -name diff-dark-stats 2>/dev/null')
  if not p then return end
  local out = p:read('a'); p:close()
  local x = out:match('Absolute upper%-left X:%s+(%-?%d+)')
  local y = out:match('Absolute upper%-left Y:%s+(%-?%d+)')
  if not (x and y) then return end
  local pos = x .. ' ' .. y
  if last_pos == nil then last_pos = pos return end -- posição de nascimento
  if pos ~= last_pos then
    local f = io.open(POS_FILE, 'w')
    if f then f:write(pos, '\n'); f:close() end
    last_pos = pos
  end
end

function conky_stats()
  remember_position()
  with_surface(function(cr, W)
    card(cr, 20, 1, W - 40, 200)
    local cw = (W - 40) / 3
    ring(cr, 20 + cw * 0.5, 76, 30, num('${cpu cpu0}'), C.sage, 'CPU')
    ring(cr, 20 + cw * 1.5, 76, 30, num('${memperc}'), C.grey, 'RAM')
    ring(cr, 20 + cw * 2.5, 76, 30, num('${fs_used_perc /}'), C.grey, 'DISCO')

    font(cr, UI_FONT, 10.5); rgba(cr, C.dim)
    text(cr, 'up ' .. conky_parse('${uptime_short}') .. '  ·  load ' .. conky_parse('${loadavg 1}'),
      W / 2, 179, 'center')
  end)
end
