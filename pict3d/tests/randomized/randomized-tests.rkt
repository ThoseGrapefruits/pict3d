#lang racket

(require racket/gui/base
         redex/reduction-semantics)

(define num-tessellate-vs-orig-tests 100)
(define num-tessellate-bbox-vs-orig-bbox-tests 100)
(define num-ray-trace-vs-opengl-tests 100)

(define-language simple-pict3d
  [posnum  #i1 #i1/2 #i1/4 #i1/8 #i1/16]
  [nz  posnum (- posnum)]
  [nn  0 posnum]
  [n  0 nz]
  [angle  0 15 30 45 60 75 90 105 120 135 150 165 180 195 210 225 240 255 270 285 300 315 330 345]
  [b  #t #f]
  [tag  variable-not-otherwise-mentioned]
  [scene  (combine scene scene)
          (freeze scene)
          (group scene 'tag)
          (rotate scene (dir nz nz nz) angle)
          (scale scene (dir nz nz nz))
          (move scene (dir n n n))
          shape]
  [shape  (ellipsoid (pos n n n) (dir nz nz nz) #:inside? b)
          (rectangle (pos n n n) (dir nz nz nz) #:inside? b)
          (cylinder (pos n n n) (dir nz nz nz) #:arc (arc angle angle) #:inside? b)
          (cone (pos n n n) (dir nz nz nz) #:arc (arc angle angle) #:inside? b)
          (triangle (pos n n n) (pos n n n) (pos n n n) #:back? b)
          (quad (pos n n n) (pos n n n) (pos n n n) (pos n n n) #:back? b)
          (pipe (pos n n n) (dir nz nz nz)
                #:bottom-radii (interval nn nn)
                #:top-radii (interval nn nn)
                #:arc (arc angle angle)
                #:inside? b)
          ])


(printf "Randomized test: tessellated bbox vs. original bbox~n")
(parameterize ([current-namespace  (make-gui-namespace)])
  (eval '(require pict3d
                  "check-tessellate-bbox-vs-orig-bbox.rkt"))
  (for ([i  (in-range num-tessellate-bbox-vs-orig-bbox-tests)])
    (when (zero? (modulo i 10))
      (printf "i = ~v~n~n" i))
    (define term (generate-term simple-pict3d scene 7))
    (printf "Testing ~v~n~n" term)
    (eval `(check-tessellate-bbox-vs-orig-bbox ,term))))