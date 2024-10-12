#lang racket

(require pict3d
         images/flomap
         pict3d/private/math)

(provide check-tessellate-bbox-vs-orig-bbox)

(define (tess p)
  (tessellate p #:segments 16 #:max-angle 5))

(define-syntax-rule (check-tessellate-bbox-vs-orig-bbox p-stx)
  (with-handlers ([exn:fail?  (λ (e) (eprintf "Error ~v on ~a~n" e 'p-stx))])
    (let ([p  p-stx])
      (define t ((current-pict3d-auto-camera) p))
      (define-values (b00 b01) (bounding-rectangle p))
      (define-values (b10 b11) (bounding-rectangle (tess p)))
      (define delta- (flv3- b10 b00))
      (define delta+ (flv3- b11 b01))
      (define max-error (max 
        (flv3-ref delta- 0)
        (flv3-ref delta- 1)
        (flv3-ref delta- 2)
        (flv3-ref delta+ 0)
        (flv3-ref delta+ 1)
        (flv3-ref delta+ 2)))
      (cond [(< max-error 0.04)  #t]
            [else
             (eprintf "Tessellate test failed with max error ~v on ~a~n"
                      max-error
                      'p-stx)
             (eprintf "Original~n~v ~v~n" b00 b01)
             (eprintf "Tessellated~n~v ~v~n" b10 b11)
             (eprintf "Absolute difference~n~v~n" (flomap->bitmap diff-fm))
             #f]))))
