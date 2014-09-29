#lang racket/base

(require racket/fixnum
         racket/gui
         racket/class
         (only-in typed/racket/base assert index?)
         math/flonum
         typed/opengl
         "../math/flt3.rkt"
         "../engine/scene.rkt"
         "../engine/utils.rkt"
         "../gl.rkt"
         "parameters.rkt"
         "pict3d-struct.rkt"
         )

(provide (contract-out
          [pict3d->bitmap  (-> pict3d? (and/c index? (>/c 0)) (and/c index? (>/c 0))
                               (is-a?/c bitmap%))]))

(define get-the-bytes (make-cached-vector 'get-the-bytes make-bytes bytes-length))
(define get-tmp-bytes (make-cached-vector 'get-tmp-bytes make-bytes bytes-length))

;(: pict3d->bitmap (-> Pict3D Integer Integer (Instance Bitmap%)))
(define (pict3d->bitmap pict width height)
  (define view (pict3d-view-transform pict))
  ;; Compute a projection matrix
  (define znear (current-pict3d-z-near))
  (define zfar (current-pict3d-z-far))
  (define fov-radians (degrees->radians (fl (current-pict3d-fov-degrees))))
  (define proj (perspective-flt3/viewport (fl width) (fl height) fov-radians znear zfar))
  (define bm (make-bitmap width height))
  ;; Lock everything up for drawing
  (with-gl-context (get-master-gl-context)
    ;; Draw the scene
    (draw-scene (pict3d-scene pict) width height
                view proj
                (current-pict3d-background)
                (current-pict3d-ambient-color)
                (current-pict3d-ambient-intensity))
    
    ;; Get the resulting pixels, upside-down (OpenGL origin is lower-left; we use upper-left)
    (define row-size (* width 4))
    (define bs (get-the-bytes (assert (* row-size height) index?)))
    (glReadPixels 0 0 width height GL_BGRA GL_UNSIGNED_INT_8_8_8_8 bs)
    
    ;; Flip right-side-up
    (define tmp (get-tmp-bytes row-size))
    (for ([row  (in-range (fxquotient height 2))])
      (define i0 (* row row-size))
      (define i1 (* (- (- height row) 1) row-size))
      (bytes-copy! tmp 0 bs i0 (+ i0 row-size))
      (bytes-copy! bs i0 bs i1 (+ i1 row-size))
      (bytes-copy! bs i1 tmp 0 row-size))
    
    (send bm set-argb-pixels 0 0 width height bs #f #t))
  bm)