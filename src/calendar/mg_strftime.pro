; docformat = 'rst'

;+
; Return a string representing a Julian date using a subset of the C strftime
; format codes.
;
; Accepted codes: %y, %Y, %d, %a, %m, %b, %j, %H, %I, %M, %S, %f, %p, %c, %x,
; and %X.
;
; :Returns:
;   string
;
; :Params:
;   date : in, required, type=double
;     Julian date
;   format : in, required, type=string
;     format specification
;-
function mg_strftime, date, format
  compile_opt strictarr

  ; find information
  caldat, date, month, day, year, hour, minute, second
  day_of_week = string(date, format='(C(CDwA))')
  month_name = string(date, format='(C(CMoA))')
  ampm = string(date, format='(C(CAPA))')

  ; perform substitution
  result = format
  s = hash('%y', string(year mod 100, format='(%"%02d")'), $
           '%Y', string(year, format='(%"%04d")'), $
           '%d', string(day, format='(%"%02d")'), $
           '%a', day_of_week, $
           '%m', string(month, format='(%"%02d")'), $
           '%b', month_name, $
           '%j', string(mg_ymd2doy(year, month, day), format='(%"%03d")'), $
           '%H', string(hour, format='(%"%02d")'), $
           '%I', string(hour gt 12 ? hour - 12 : hour, format='(%"%02d")'), $
           '%M', string(minute, format='(%"%02d")'), $
           '%S', string(second, format='(%"%02d")'), $
           '%f', string(1000000L * (second - long(second)), format='(%"%06d")'), $
           '%p', ampm, $
           '%c', string(day_of_week, $
                        month_name, $
                        day, $
                        hour, minute, second, $
                        year, $
                        format='(%"%s %s %02d %02d:%02d:%02d %04d")'), $
           '%x', string(month, day, year, format='(%"%02d/%02d/%04d")'), $
           '%X', string(hour, minute, second, format='(%"%02d:%02d:%02d")'))
  foreach value, s, code do result = mg_streplace(result, code, value, /global)

  return, result
end


; main-level example program

print, mg_strftime(systime(/julian), '%a %b %d %H:%M:%S %Y -- %Y%m%d.%H%M%S %p')

end
