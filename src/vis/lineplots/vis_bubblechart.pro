; docformat = 'rst'

;+
; Create a simple bubblechart.
;
; :Examples:
;    Try the main-level example program at the end of this file::
;
;       IDL> .run vis_bubblechart
;
;    This should produce the following:
;
;    .. image:: bubblechart.png
;-


;+
; Plot the bubbles.
;
; :Params:
;    x : in, required, type=fltarr
;    y: in, required, type=fltarr
;
; :Keywords:
;    size : in, required, type=fltarr
;       array of bubble sizes
;    color : in, required, type=bytarr/lonarr
;       array of color values
;    _extra : in, optional, type=keywords
;       POLYFILL keywords
;-
pro vis_bubblechart_overplot, x, y, size=size, color=color, _extra=e
  compile_opt strictarr
  
  n = 20
  t = findgen(n) / (n - 1.) * 360. * !dtor
  dx = cos(t)
  dy = sin(t)
  nsize = n_elements(size)
  ncolor = n_elements(color)
  
  npoints = n_elements(x)
  for p = 0L, npoints - 1L do begin
    polyfill, dx * size[p mod nsize] + x[p], dy * size[p mod nsize] + y[p], $
              color=color[p mod ncolor], _extra=e 
  endfor
end


;+
;-
pro vis_bubblechart, x, y, size=size, area=area, $
                     color=color, axes_color=axesColor, $
                     overplot=overplot, $
                     _extra=e
  compile_opt strictarr
  
  if (~keyword_set(overplot)) then begin
    plot, x, y, color=axesColor, /nodata, _extra=e
  endif
  
  if (n_elements(size) eq 0L) then begin
    minx = min(x, max=maxx)
    miny = min(y, max=maxy)
    
    _size = ((maxx - minx) < (maxy - miny)) / 100.
  endif else begin
    _size = size
  endelse
  
  if (keyword_set(area)) then _size = sqrt(_size / !pi)
  
  _color = n_elements(color) eq 0L ? 'ffffff'x : color
  
  vis_bubblechart_overplot, x, y, size=_size, color=_color, _extra=e
end


; main-level example program

n = 40
x = randomu(seed, n)
y = randomu(seed, n)
size = 0.05 * randomu(seed, n)
color = fix(randomu(seed, n) * 12)

ps = 1
if (keyword_set(ps)) then begin
  orig_device = !d.name
  vis_psbegin, filename='bubblechart.ps'
endif

vis_decomposed, 0, old_decomposed=old_dec
vis_loadct, 27, /brewer
tvlct, 0, 0, 0, 12
tvlct, 255, 255, 255, 13

vis_window, xsize=3, ysize=3, /inches
vis_bubblechart, x, y, axes_color=12, background=13, size=size, color=color, $
                 position=[0.1, 0.1, 0.95, 0.95], charsize=0.7

vis_decomposed, old_dec
if (keyword_set(ps)) then begin
  vis_psend
  vis_convert, 'bubblechart', max_dimension=[400, 400], output=im
  vis_image, im, /new_window
endif
end