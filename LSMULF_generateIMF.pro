; LSMULF_generateIMF.pro
;
; Program to generate IMF.dat files for SWMF/CIMI studies of Large
; Scale, Monochromatic ULF waves on the radiation belts.
;
; Written by Michael Hartinger, 7-7-2017
;
; Notes:
; The driving conditions in this script are based on (1) NASA proposal
; on LSM ULF waves, (2) Degeling et al., 2008,2011, Kepko et al., 2003,
; and Viall et al., 2009, and Claudepierre et al., 2009.
;
; The LSM ULF wave is generated by a density variation in the solar
; wind, while magnetic field values are held fixed. An out of phase
; temperature variation is added so thermal pressure is constant, as
; in Claudepierre et al., 2009. In contrast to Claudepierre et al.,
; 2009, IMF Bz is northward and vsw=400 km/s. This is similar to Komar
; et al., 2017.
;
; The default values are meant to mimic Degeling et al., 2008 as
; closely as possible, to make qualitative comparisons with CIMI
; non-diffusive behavior straightforward (e.g., Figure 4 in Degeling
; et al., 2008).
;
; A range of values are also shown in comments below. In the NASA
; proposal, we noted that we would vary amplitude, frequency,
; duration, bandwidth, and radial PSD profile. Only the first four are
; varied in this script. For now, these are varied according to
; functional forms given in Degeling et al., 2008, 2011. The event
; duration is a Gaussian, rather than rise/fall time form in Degeling
; study.
;
; As for radial PSD profile, past studies such as Degeling et al. 2008
; used monotonic PSD profile for the initial condition that varied as
; L^-6. I think the default CIMI profile should be fine to start with
; - looking at Figure 4 in Degeling et al., 2008 and Figures in Komar
; et al., 2017, I bet we'll be able to replicate their results, at
; least qualitatively, but it will be interesting to see how varying
; the PSD profile affects the results (Degeling didn't do this), as
; well as some of the other wave properties.
;

pro LSMULF_generateIMF

;***CONSTANTS

  k = 1.38e-23
  gamma = 5. / 3.
  mi = 1.67e-27

; background sound speed is 40 km/s, as in Claudierre et al., 2009

  cs = 40e3
  Temp0 = ( mi * cs ^ 2. ) / ( gamma * k )
  print, "TEMP0: ", temp0
; simulation length in hours - should be at least four hours

  simlength = 12.

; Time resolution - 10 seconds should be more than enough to capture
;                   the frequencies we're interested in (below 5 mHz),
;                   and we could possibly increase to 30 seconds if
;                   computer time is an issue

  simres = 10.

; peak time of Gaussian wave packet is 3 hours into the simulation

  ts = 6. * 60. * 60.

; define time array in seconds

  npts = simlength * 60. * 60. / simres + 1.
  t = DINDGEN( npts ) * simres
  
; millescond array for IMF file

  msecs = FLTARR( npts )

; get year, month, day, hour, minute, second arrays that will be used
; for output file the start time is meaningless since these are
; idealized simulations
  
  jult = JULDAY( 2, 2, 2002, 1, 1, t )
  CALDAT, jult, M, D, Y, HH, MINS, S

; ***OPTIONS FOR WAVE PARAMETERS
; DEFAULTS, An = .2,f = .003,tau = 6,dw = 0
; amplitude as fraction of background density
  
  An = [ .1, .15, .2, .25, .3 ]

; frequency options in Hz

  f = [ .001, .002, .003, .004, .005 ]

; duration of wave packet in units of wave period

  tau = [ 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24 ]

; Bandwidth options in units of width of flat top spectrum as function
; of frequency.  Whatever width is chosen, the spacing of frequency
; elements will be .0001 Hz.  i.e., of f = .003 and dw = .2, the spectrum
; will consists of frequencies at
; .0024,.0025,.0026,....0034,.0035,.0036 if 0 is chosen, only a single
; frequency will be used

  dw = [ 0, .1, .2, .3, .4 ]

; Define solar wind quantities for output file. Apart from
; temperature/density variations, these are the same as in Komar et
; al., 2017 background density is 5/cc

  n0 = 5.

; density fluctuation parameters

  An1 = An( 2 ) * n0
  f1 = f( 4 )
  tau1 = tau( 1 ) * ( 1. / f1 )
  dw1 = dw( 0 )

  IF $
     ( dw1 EQ 0 ) $
  THEN BEGIN

     dn = An1 * $
          EXP( - ( ( t - ts ) / tau1 )^ 2 ) * $
          SIN( 2. * !PI * f1 * ( t - ts ) )
     
  ENDIF ELSE BEGIN

     ; define frequency array

     fmin = f1 - dw1 * f1
     fmax = f1 + dw1 * f1
     fn = ROUND( ( fmax - fmin ) / .0001 )
     farr = fmin + FINDGEN( fn ) * .0001
     
     ; modify amplitude according to number of frequency elements so
     ; integrated power is the same across runs with different bandwidth
     
     An1 = An1 / SQRT( fn )
     dn = FLTARR( npts )
     phi = 2. * !PI * RANDOMU( seed, fn )

     FOR $
        i = 0, fn - 1 $
     DO $

        ; get phase to add to each frequency component
        dn = $
        dn + $
        An1 * $
        EXP( - ( ( t - ts ) / tau1 ) ^ 2 ) * $
        SIN( 2. * !PI * farr( i ) * ( t - ts ) + phi( i ) )

  ENDELSE

  bx = FLTARR( npts )
  by = FLTARR( npts )
  bz = FLTARR( npts ) + 5.
  vx = FLTARR( npts ) - 400.
  vy = FLTARR( npts )
  vz = FLTARR( npts )
  n = n0 + dn

  Temp = FLTARR(npts) + Temp0 - ( Temp0 * dn ) / n
  
  PLOT, t / 3600., TEMP
  
  ; write file out
  OPENW, lun, '~/Research/Hartinger_HSR/IMF.dat', $
         WIDTH = 80, /GET_LUN
  format_string = '( I4, 1X, I02, 1X, I02, 1X, I02, 1X, I02, 1X, ' + $
                 'I02, 1X, I03, 1X, F7.1, 1X, F7.1, 1X, ' + $
                 'F7.1, 1X, F7.1, 1X, F7.1, 1X, F7.1, 1X, F7.3, ' + $
                 '2X, F10.2 )'
  PRINTF, lun, TRANSPOSE( [ [ Y ], [ M ], [ D ], $
                            [ HH ], [ MINS ], [ S ], [ msecs ], $
                            [ bx ], [ by ], [ bz ], $
                            [ vx ], [ vy ], [ vz ], $
                            [ n ], [ Temp ] ] ), $
          FORMAT = format_string
  CLOSE, lun
  FREE_LUN, lun
  
END
