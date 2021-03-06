; docformat = 'rst'

function mg_scatterplot_matrix_format, axis, index, value
  compile_opt strictarr
  common mg_scatterplot_matrix_common, display_axis, _ticks, _xformat, _yformat

  if (~display_axis[axis] || index eq 0 || index eq _ticks[axis]) then return, ' '
  if (axis eq 0 && n_elements(_xformat) gt 0L) then return, string(value, format=_xformat)
  if (axis eq 1 && n_elements(_yformat) gt 0L) then return, string(value, format=_yformat)

  return, strtrim(value, 2)
end


;+
; Compute normal coordinates for subplot.
;
; :Private:
; 
; :Returns:
;   `fltarr(4)`
;
; :Params:
;   col : in, required, type=integer
;     column (0 is leftmost)
;   row : in, required, type=integer
;     row (0 is topmost)
;
; :Keywords:
;   dimension : in, required, type=integer
;     number of rows/columns in matrix
;-
function mg_scatterplot_matrix_position, col, row, $
                                         dimension=dimension, $
                                         position=position
  compile_opt strictarr

  _position = n_elements(position) eq 0L ? [0.1, 0.1, 0.975, 0.975] : position

  pos = [float(col) / dimension, $
         1.0 - (row + 1.0) / dimension, $
         (col + 1.0) / dimension, $
         1.0 - float(row) / dimension]

  ; now convert to inside POSITION
  x_range = [0.1, 0.975]
  y_range = [0.1, 0.975]
  return, [pos[0] * (_position[2] - _position[0]) + _position[0], $
           pos[1] * (_position[3] - _position[1]) + _position[1], $
           pos[2] * (_position[2] - _position[0]) + _position[0], $
           pos[3] * (_position[3] - _position[1]) + _position[1]]
end


;+
; Create a matrix of scatter plots.
;
; :Examples:
;   Try the main-level example program at the end of this file::
;
;     IDL> .run mg_scatterplot_matrix
;
;   This should produce:
;
;   .. image:: scatterplot_matrix-example.png
;
; :Params:
;   data : in, required, type="fltarr(m, n) or array of n structures with m fields"
;     m data sets of n elements each
;
; :Keywords:
;   column_names : in, optional, type=strarr
;     x- and y-titles
;   _extra : in, optional, type=keywords
;     keywords to `PLOT`, `MG_HISTPLOT`, or `HISTOGRAM` routines
;-
pro mg_scatterplot_matrix, data, column_names=column_names, $
                           bar_color=bar_color, $
                           psym=psym, symsize=symsize, $
                           axis_color=axis_color, color=color, $
                           position=position, $
                           n_bins=n_bins, $
                           xticks=xticks, yticks=yticks, $
                           xtickformat=xtickformat, $
                           ytickformat=ytickformat, $
                           _extra=e
  compile_opt strictarr
  on_error, 2
  common mg_scatterplot_matrix_common, display_axis, _ticks, _xformat, _yformat

  if (n_elements(xtickformat) gt 0L) then _xformat = xtickformat
  if (n_elements(ytickformat) gt 0L) then _yformat = ytickformat

  _xticks = mg_default(xticks, 1) + 2
  _yticks = mg_default(yticks, 1) + 2
  _ticks = [_xticks, _yticks]

  show_xtickname = strarr(_xticks + 1) + ''
  show_xtickname[[0, _xticks]] = ' '
  hide_xtickname = strarr(40) + ' '

  show_ytickname = strarr(_yticks + 1) + ''
  show_ytickname[[0, _yticks]] = ' '
  hide_ytickname = strarr(40) + ' '

  _psym = n_elements(psym) eq 0L ? 3 : psym
  if (size(data, /type) eq 8) then begin
    is_struct = 1B
    dims = [n_tags(data[0]), n_elements(data)]
  endif else begin
    is_struct = 0B
    dims = size(data, /dimensions)
  endelse
  _column_names = n_elements(column_names) eq 0L ? strarr(dims[0]) : column_names

  if (n_elements(_column_names) ne dims[0]) then message, 'invalid number of column names'

  x_range = fltarr(2, dims[0])
  y_range = fltarr(2, dims[0])

  ; plot histograms on diagonal
  _n_bins = mg_default(n_bins, 20)
  for row = 0L, dims[0] - 1L do begin
    col = row
    h = histogram(is_struct ? data.(row) : data[row, *], $
                  locations=bins, nbins=_n_bins, _extra=e)
    mg_histplot, bins, h, /fill, axis_color=axis_color, color=bar_color, $
                 position=mg_scatterplot_matrix_position(col, row, dimension=dims[0], position=position), $
                 xtitle=row eq (dims[0] - 1) ? _column_names[col] : '', $
                 xrange=x_range[*, col], yrange=[0, max(h) * 1.10], $
                 xstyle=1, ystyle=1, $
                 xtickname=strarr(40) + ' ', $
                 yticks=1, yminor=1, ytickname=strarr(2) + ' ', $
                 xticklen=0.000001, $  ; bug in IDL? 0.0 doesn't work
                 /noerase, _extra=e
    x_range[*, row] = !x.crange
  endfor

  ; plot one scatterplot per row and store y-range so later scatterplots have
  ; the exact same range
  for row = 0L, dims[0] - 1L do begin
    col = (row + dims[0] - 1) mod dims[0]
    display_axis = [row eq [dims[0] - 1], col eq 0L]
    plot, is_struct ? data.(col) : data[col, *], is_struct ? data.(row) : data[row, *], $
          /nodata, /noerase, $
          xtitle=row eq (dims[0] - 1) ? _column_names[col] : '', $
          ytitle=col eq 0L ? _column_names[row] : '', $
          color=axis_color, $
          position=mg_scatterplot_matrix_position(col, row, dimension=dims[0], position=position), $
          xrange=x_range[*, col], $
          xstyle=1, /ynozero, $
          xtickname=row eq [dims[0] - 1] ? show_xtickname : hide_xtickname, $
          ytickname=col eq 0L ? show_ytickname : hide_ytickname, $
          xticks=_xticks, yticks=_yticks, $
          xtickformat='mg_scatterplot_matrix_format', $
          ytickformat='mg_scatterplot_matrix_format', $
          _extra=e
    y_range[*, row] = !y.crange
    mg_plots, is_struct ? data.(col) : reform(data[col, *]), $
              is_struct ? data.(row) : reform(data[row, *]), $
              psym=_psym, color=color, symsize=symsize, _extra=e
  endfor

  ; plot scatterplots
  for row = 0L, dims[0] - 1L do begin
    for col = 0L, dims[0] - 1L do begin
      ; skip subdiagonal (and upper right) where already plotted to get ranges
      if (col eq (row + dims[0] - 1) mod dims[0]) then continue

      ; upper left corner is special: need to get axis for scatterplots
      ; instead of the histogram that is displayed next to it (XSTYLE/YSTYLE
      ; differ from other plots and no MG_PLOTS)
      if (row eq 0 && col eq 0) then begin
        display_axis = [row eq [dims[0] - 1], col eq 0L]
        plot, is_struct ? data.(col) : data[col, *], $
              is_struct ? data.(row) : data[row, *], $
              /nodata, /noerase, $
              xtitle=row eq (dims[0] - 1) ? _column_names[col] : '', $
              ytitle=col eq 0L ? _column_names[row] : '', $
              color=axis_color, $
              position=mg_scatterplot_matrix_position(col, row, dimension=dims[0], position=position), $
              xrange=x_range[*, col], yrange=y_range[*, row], $
              xstyle=5, ystyle=9, $
              xtickname=row eq [dims[0] - 1] ? show_xtickname : hide_xtickname, $
              ytickname=col eq 0L ? show_ytickname : hide_ytickname, $
              xticks=_xticks, yticks=_yticks, $
              xtickformat='mg_scatterplot_matrix_format', $
              ytickformat='mg_scatterplot_matrix_format', $
              _extra=e
      endif

      if ((row eq dims[0] - 1) && (col eq dims[0] - 1)) then begin
        display_axis = [row eq [dims[0] - 1], col eq 0L]
        plot, is_struct ? data.(col) : data[col, *], $
              is_struct ? data.(row) : data[row, *], $
              /nodata, /noerase, $
              xtitle=row eq (dims[0] - 1) ? _column_names[col] : '', $
              ytitle=col eq 0L ? _column_names[row] : '', $
              color=axis_color, $
              position=mg_scatterplot_matrix_position(col, row, dimension=dims[0], position=position), $
              xrange=x_range[*, col], yrange=y_range[*, row], $
              xstyle=9, ystyle=5, $
              xtickname=row eq [dims[0] - 1] ? show_xtickname : hide_xtickname, $
              ytickname=col eq 0L ? show_ytickname : hide_ytickname, $
              xticks=_xticks, yticks=_yticks, $
              xtickformat='mg_scatterplot_matrix_format', $
              ytickformat='mg_scatterplot_matrix_format', $
              _extra=e
      endif

      ; plot scatterplots
      if (col ne row) then begin
        display_axis = [row eq [dims[0] - 1], col eq 0L]
        plot, is_struct ? data.(col) : data[col, *], $
              is_struct ? data.(row) : data[row, *], $
              /nodata, /noerase, $
              xtitle=row eq (dims[0] - 1) ? _column_names[col] : '', $
              ytitle=col eq 0L ? _column_names[row] : '', $
              color=axis_color, $
              position=mg_scatterplot_matrix_position(col, row, dimension=dims[0], position=position), $
              xrange=x_range[*, col], yrange=y_range[*, row], $
              xstyle=1, ystyle=1, $
              xtickname=row eq [dims[0] - 1] ? show_xtickname : hide_xtickname, $
              ytickname=col eq 0L ? show_ytickname : hide_ytickname, $
              xticks=_xticks, yticks=_yticks, $
              xtickformat='mg_scatterplot_matrix_format', $
              ytickformat='mg_scatterplot_matrix_format', $
              _extra=e
        mg_plots, is_struct ? data.(col) : reform(data[col, *]), $
                  is_struct ? data.(row) : reform(data[row, *]), $
                  psym=_psym, color=color, symsize=symsize, _extra=e
      endif
    endfor
  endfor
end


; main-level example program

if (n_elements(demo) eq 0L) then demo = 0
if (n_elements(ps) eq 0L) then ps = 0

mg_constants

m = 10
n = 40
column_names = string(reform(byte((byte('A'))[0] + lindgen(m)), 1, m))

size = [10, 10]
dims = [1000, 1000]
if (keyword_set(ps)) then begin
  mg_psbegin, /color, bits_per_pixel=8, filename='scatterplot_matrix.ps'
  charsize = 0.75
  symsize = 1.0
  if (keyword_set(demo)) then begin
    size = [5.0, 5.0]
    dims = [400, 400]
    symsize = 0.5
  endif
endif else begin
  charsize = 1.0
  symsize = 0.6
endelse

mg_window, xsize=size[0], ysize=size[1], /inches, title='mg_scatterplot_matrix example'

mg_decomposed, 0, old_decomposed=odec

loadct, 0, ncolors=254
tvlct, 255, 128, 0, 255

data = randomu(seed, m, n)

mg_scatterplot_matrix, data, $
                       psym=mg_usersym(/circle), $
                       color=byte(randomu(seed, n) * 255), $
                       axis_color=254, $
                       bar_color=255, $
                       charsize=charsize, symsize=symsize, $
                       nbins=20, $
                       column_names=column_names, $
                       yticks=3, xticks=1, $
                       xtickformat='(F0.2)', $
                       ytickformat='(F0.2)'

mg_decomposed, odec

if (keyword_set(ps)) then begin
  mg_psend
  mg_convert, 'scatterplot_matrix', max_dimension=dims, output=im, $
              keep_output=keyword_set(demo)
  mg_image, im, /new_window
endif

end
