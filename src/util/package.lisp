(defpackage #:lwlgl.util
  (:use #:cl)
  (:export
   #:monotonic-seconds #:clamp #:lerp #:inverse-lerp #:smoothstep
   #:frame-clock #:make-frame-clock #:reset-frame-clock #:tick-frame-clock
   #:frame-clock-delta #:frame-clock-elapsed #:frame-clock-frame-count #:frame-clock-fps
   #:fixed-step #:make-fixed-step #:fixed-step-dt #:fixed-step-accumulator
   #:reset-fixed-step #:advance-fixed-step
   ;; Profiling
   #:profile-stat #:profile-stat-name #:profile-stat-count #:profile-stat-total #:profile-stat-last
   #:profile-stat-minimum #:profile-stat-maximum #:profile-stat-average
   #:profiler #:make-profiler #:profiler-record #:profiler-stat #:reset-profiler #:profiler-report
   #:with-profiled-section))
