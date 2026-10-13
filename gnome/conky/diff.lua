-- Diff-Dark — card de sistema (anéis de CPU/RAM/disco) desenhado em Cairo,
-- com um card opcional de cota de IA embaixo.
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
  warn    = {0xd6, 0xc0, 0x8e},
  crit    = {0xd9, 0x88, 0x80},
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

-- Cota de IA (opcional): o ai_usage.py roda em segundo plano a cada 2 min e grava
-- um resumo; aqui só se lê o arquivo. Sem o binário (AI_USAGEBAR vazio) o card não existe.
local AI_BIN = os.getenv('AI_USAGEBAR') or ''
local AI_FILE = os.getenv('HOME') .. '/.cache/diff-dark/ai-usage.tsv'
local ai, ai_fetched, ai_read = nil, -math.huge, -math.huge

local function ai_update()
  if AI_BIN == '' then return end
  local now = os.time()
  if now - ai_fetched >= 120 then
    ai_fetched = now
    os.execute('python3 -I "' .. os.getenv('DIFF_KIT') .. '/conky/ai_usage.py" >/dev/null 2>&1 &')
  end
  if now - ai_read < 5 then return end
  ai_read = now
  local f = io.open(AI_FILE)
  if not f then ai = nil return end
  local data = {}
  for line in f:lines() do
    local k, a, b, c = line:match('^(%w+)\t([^\t]*)\t?([^\t]*)\t?([^\t]*)')
    if k == 'provider' then data.provider = a
    elseif k then data[k] = {pct = tonumber(a) or 0, reset = tonumber(b) or 0, window = tonumber(c) or 0} end
  end
  f:close()
  ai = (data.session or data.week) and data or nil
end

local function countdown(secs)
  if secs <= 0 then return 'agora' end
  local d, h, m = secs // 86400, secs % 86400 // 3600, secs % 3600 // 60
  if d > 0 then return string.format('%dd %dh', d, h) end
  if h > 0 then return string.format('%dh %02dm', h, m) end
  return string.format('%dm', m)
end

-- barra fina com a cota usada e um risco no quanto da janela de tempo já passou:
-- barra além do risco = consumindo mais rápido que o relógio
local function quota_row(cr, x0, x1, y, label, q)
  local now = os.time()
  local pct = (q.reset > 0 and now >= q.reset) and 0 or q.pct
  local color = pct >= 90 and C.crit or pct >= 70 and C.warn or C.sage
  font(cr, UI_FONT, 10.5); rgba(cr, C.muted)
  text(cr, label, x0, y + 4)
  font(cr, UI_FONT, 11, true); rgba(cr, C.ink2)
  text(cr, string.format('%d%%', pct), x1, y + 4, 'right')

  local bx0, bx1 = x0 + 62, x1 - 42
  cairo_set_line_cap(cr, CAIRO_LINE_CAP_ROUND)
  cairo_set_line_width(cr, 4)
  rgba(cr, C.track)
  cairo_new_path(cr); cairo_move_to(cr, bx0, y); cairo_line_to(cr, bx1, y); cairo_stroke(cr)
  if pct > 0 then
    rgba(cr, color)
    cairo_new_path(cr); cairo_move_to(cr, bx0, y)
    cairo_line_to(cr, bx0 + (bx1 - bx0) * math.min(pct, 100) / 100, y); cairo_stroke(cr)
  end
  if q.window > 0 and q.reset > now then
    local elapsed = 1 - (q.reset - now) / q.window
    local tx = bx0 + (bx1 - bx0) * math.max(0, math.min(1, elapsed))
    cairo_set_line_cap(cr, CAIRO_LINE_CAP_BUTT)
    cairo_set_line_width(cr, 1.5)
    rgba(cr, C.muted, 0.9)
    cairo_new_path(cr); cairo_move_to(cr, tx, y - 6); cairo_line_to(cr, tx, y + 6); cairo_stroke(cr)
  end
end

local function ai_card(cr, W, y0)
  card(cr, 20, y0, W - 40, 112)
  local x0, x1 = 40, W - 40
  font(cr, UI_FONT, 9.5, true); rgba(cr, C.dim)
  text(cr, (ai.provider or 'IA'):upper(), x0, y0 + 24)
  local now, y, resets = os.time(), y0 + 48, {}
  for _, row in ipairs({{'session', 'Sessão', 'sessão'}, {'week', 'Semana', 'semana'}}) do
    local q = ai[row[1]]
    if q then
      quota_row(cr, x0, x1, y, row[2], q)
      if q.reset > 0 then resets[#resets + 1] = row[3] .. ' ' .. countdown(q.reset - now) end
      y = y + 24
    end
  end
  font(cr, UI_FONT, 10); rgba(cr, C.dim)
  if #resets > 0 then text(cr, 'zera: ' .. table.concat(resets, '  ·  '), W / 2, y0 + 100, 'center') end
end

function conky_stats()
  ai_update()
  with_surface(function(cr, W)
    card(cr, 20, 1, W - 40, 200)
    local cw = (W - 40) / 3
    ring(cr, 20 + cw * 0.5, 76, 30, num('${cpu cpu0}'), C.sage, 'CPU')
    ring(cr, 20 + cw * 1.5, 76, 30, num('${memperc}'), C.grey, 'RAM')
    ring(cr, 20 + cw * 2.5, 76, 30, num('${fs_used_perc /}'), C.grey, 'DISCO')

    font(cr, UI_FONT, 10.5); rgba(cr, C.dim)
    text(cr, 'up ' .. conky_parse('${uptime_short}') .. '  ·  load ' .. conky_parse('${loadavg 1}'),
      W / 2, 179, 'center')

    if ai then ai_card(cr, W, 213) end
  end)
end
