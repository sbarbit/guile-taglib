(define-module (taglib)
  #:use-module (system foreign)
  #:use-module (ice-9 format))

(define dll (dynamic-link "libtag_c.so"))

(define-wrapped-pointer-type taglib-file
  taglib-file?
  wrap-taglib
  unwrap-taglib
  (lambda (o p)
    (format p "#<taglib:file ~x>" (pointer-address (unwrap-taglib o)))))

(define-public taglib-open
  (let [(ffi (pointer->procedure '*
				 (dynamic-func "taglib_file_new" dll)
				 (list '*)))]
    (lambda (filename)
      (let [(handle (ffi (string->pointer filename)))]
	(if (null-pointer? handle) #f
	    (begin
	      (set-pointer-finalizer! handle (dynamic-func "taglib_file_free" dll))
	      (wrap-taglib handle)))))))

(define-public taglib-save
  (compose
   (pointer->procedure int
		       (dynamic-func "taglib_file_save" dll)
		       (list '*))
   unwrap-taglib))

(define taglib-file-tag
  (compose
   (pointer->procedure '*
		       (dynamic-func "taglib_file_tag" dll)
		       (list '*))
   unwrap-taglib))


(define (wrap-with-string-setter g s)
  (let [(getter (pointer->procedure '* (dynamic-func g dll) (list '*)))
	(setter (pointer->procedure void (dynamic-func s dll) (list '* '*)))]
    (make-procedure-with-setter
     (compose pointer->string getter taglib-file-tag)
     (lambda (handle str) (setter (taglib-file-tag handle) (string->pointer str))))))

(define (wrap-with-int-setter g s)
  (let [(getter (pointer->procedure int (dynamic-func g dll) (list '*)))
	(setter (pointer->procedure void (dynamic-func s dll) (list '* int)))]
    (make-procedure-with-setter
     (compose getter taglib-file-tag)
     (lambda (handle val)
       (setter (taglib-file-tag handle) val)))))

(define-public artist (wrap-with-string-setter "taglib_tag_artist" "taglib_tag_set_artist"))
(define-public title (wrap-with-string-setter "taglib_tag_title" "taglib_tag_set_title"))
(define-public album (wrap-with-string-setter "taglib_tag_album" "taglib_tag_set_album"))
(define-public genre (wrap-with-string-setter "taglib_tag_genre" "taglib_tag_set_genre"))
(define-public comment (wrap-with-string-setter "taglib_tag_comment" "taglib_tag_set_comment"))
(define-public year (wrap-with-int-setter "taglib_tag_year" "taglib_tag_set_year"))
(define-public track (wrap-with-int-setter "taglib_tag_track" "taglib_tag_set_track"))

(define (wrap-audio-property cproc)
  (compose (pointer->procedure int (dynamic-func cproc dll) (list '*))
	   (pointer->procedure '* (dynamic-func "taglib_file_audioproperties" dll)(list '*))
	   unwrap-taglib))

(define-public audio-length (wrap-audio-property "taglib_audioproperties_length"))
(define-public audio-bitrate (wrap-audio-property "taglib_audioproperties_bitrate"))
(define-public audio-samplerate (wrap-audio-property "taglib_audioproperties_samplerate"))
(define-public audio-channels (wrap-audio-property "taglib_audioproperties_channels"))
