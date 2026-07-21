(in-package #:lwlgl.opengl)

(define-gl-function gl-clear-color "glClearColor" :void
  ((red-value :float) (green :float) (blue :float) (alpha :float)))
(define-gl-function gl-clear "glClear" :void ((mask :unsigned-int)))
(define-gl-function gl-viewport "glViewport" :void ((x :int) (y :int) (width :int) (height :int)))
(define-gl-function gl-scissor "glScissor" :void ((x :int) (y :int) (width :int) (height :int)))
(define-gl-function gl-enable "glEnable" :void ((cap :unsigned-int)))
(define-gl-function gl-disable "glDisable" :void ((cap :unsigned-int)))
(define-gl-function gl-blend-func "glBlendFunc" :void ((sfactor :unsigned-int) (dfactor :unsigned-int)))
(define-gl-function gl-blend-equation "glBlendEquation" :void ((mode :unsigned-int)))
(define-gl-function gl-depth-func "glDepthFunc" :void ((function :unsigned-int)))
(define-gl-function gl-cull-face "glCullFace" :void ((mode :unsigned-int)))
(define-gl-function gl-front-face "glFrontFace" :void ((mode :unsigned-int)))
(define-gl-function gl-polygon-mode "glPolygonMode" :void ((face :unsigned-int) (mode :unsigned-int)))
(define-gl-function gl-line-width "glLineWidth" :void ((width :float)))

(define-gl-function gl-gen-buffers "glGenBuffers" :void ((n :int) (buffers :pointer)))
(define-gl-function gl-delete-buffers "glDeleteBuffers" :void ((n :int) (buffers :pointer)))
(define-gl-function gl-bind-buffer "glBindBuffer" :void ((target :unsigned-int) (buffer :unsigned-int)))
(define-gl-function gl-buffer-data "glBufferData" :void
  ((target :unsigned-int) (size :ptrdiff) (data :pointer) (usage :unsigned-int)))
(define-gl-function gl-buffer-sub-data "glBufferSubData" :void
  ((target :unsigned-int) (offset :ptrdiff) (size :ptrdiff) (data :pointer)))
(define-gl-function gl-bind-buffer-base "glBindBufferBase" :void
  ((target :unsigned-int) (index :unsigned-int) (buffer :unsigned-int)))

(define-gl-function gl-gen-vertex-arrays "glGenVertexArrays" :void ((n :int) (arrays :pointer)))
(define-gl-function gl-delete-vertex-arrays "glDeleteVertexArrays" :void ((n :int) (arrays :pointer)))
(define-gl-function gl-bind-vertex-array "glBindVertexArray" :void ((array :unsigned-int)))
(define-gl-function gl-vertex-attrib-pointer "glVertexAttribPointer" :void
  ((index :unsigned-int) (size :int) (type :unsigned-int) (normalized :unsigned-char)
   (stride :int) (pointer :pointer)))
(define-gl-function gl-enable-vertex-attrib-array "glEnableVertexAttribArray" :void ((index :unsigned-int)))
(define-gl-function gl-disable-vertex-attrib-array "glDisableVertexAttribArray" :void ((index :unsigned-int)))
(define-gl-function gl-vertex-attrib-divisor "glVertexAttribDivisor" :void ((index :unsigned-int) (divisor :unsigned-int)))

(define-gl-function gl-create-shader "glCreateShader" :unsigned-int ((type :unsigned-int)))
(define-gl-function gl-shader-source "glShaderSource" :void
  ((shader :unsigned-int) (count :int) (strings :pointer) (lengths :pointer)))
(define-gl-function gl-compile-shader "glCompileShader" :void ((shader :unsigned-int)))
(define-gl-function gl-get-shader-iv "glGetShaderiv" :void
  ((shader :unsigned-int) (pname :unsigned-int) (params :pointer)))
(define-gl-function gl-get-shader-info-log "glGetShaderInfoLog" :void
  ((shader :unsigned-int) (buf-size :int) (length :pointer) (info-log :pointer)))
(define-gl-function gl-delete-shader "glDeleteShader" :void ((shader :unsigned-int)))

(define-gl-function gl-create-program "glCreateProgram" :unsigned-int ())
(define-gl-function gl-attach-shader "glAttachShader" :void ((program :unsigned-int) (shader :unsigned-int)))
(define-gl-function gl-detach-shader "glDetachShader" :void ((program :unsigned-int) (shader :unsigned-int)))
(define-gl-function gl-link-program "glLinkProgram" :void ((program :unsigned-int)))
(define-gl-function gl-get-program-iv "glGetProgramiv" :void
  ((program :unsigned-int) (pname :unsigned-int) (params :pointer)))
(define-gl-function gl-get-program-info-log "glGetProgramInfoLog" :void
  ((program :unsigned-int) (buf-size :int) (length :pointer) (info-log :pointer)))
(define-gl-function gl-use-program "glUseProgram" :void ((program :unsigned-int)))
(define-gl-function gl-delete-program "glDeleteProgram" :void ((program :unsigned-int)))
(define-gl-function gl-get-attrib-location "glGetAttribLocation" :int ((program :unsigned-int) (name :string)))
(define-gl-function gl-get-uniform-location "glGetUniformLocation" :int ((program :unsigned-int) (name :string)))
(define-gl-function gl-get-uniform-block-index "glGetUniformBlockIndex" :unsigned-int
  ((program :unsigned-int) (name :string)))
(define-gl-function gl-uniform-block-binding "glUniformBlockBinding" :void
  ((program :unsigned-int) (uniform-block-index :unsigned-int) (uniform-block-binding :unsigned-int)))
(define-gl-function gl-uniform-1f "glUniform1f" :void ((location :int) (v0 :float)))
(define-gl-function gl-uniform-2f "glUniform2f" :void ((location :int) (v0 :float) (v1 :float)))
(define-gl-function gl-uniform-3f "glUniform3f" :void ((location :int) (v0 :float) (v1 :float) (v2 :float)))
(define-gl-function gl-uniform-4f "glUniform4f" :void ((location :int) (v0 :float) (v1 :float) (v2 :float) (v3 :float)))
(define-gl-function gl-uniform-1i "glUniform1i" :void ((location :int) (v0 :int)))
(define-gl-function gl-uniform-2i "glUniform2i" :void ((location :int) (v0 :int) (v1 :int)))
(define-gl-function gl-uniform-3i "glUniform3i" :void ((location :int) (v0 :int) (v1 :int) (v2 :int)))
(define-gl-function gl-uniform-4i "glUniform4i" :void ((location :int) (v0 :int) (v1 :int) (v2 :int) (v3 :int)))
(define-gl-function gl-uniform-matrix-3fv "glUniformMatrix3fv" :void
  ((location :int) (count :int) (transpose :unsigned-char) (value :pointer)))
(define-gl-function gl-uniform-matrix-4fv "glUniformMatrix4fv" :void
  ((location :int) (count :int) (transpose :unsigned-char) (value :pointer)))

(define-gl-function gl-draw-arrays "glDrawArrays" :void ((mode :unsigned-int) (first :int) (count :int)))
(define-gl-function gl-draw-elements "glDrawElements" :void
  ((mode :unsigned-int) (count :int) (type :unsigned-int) (indices :pointer)))
(define-gl-function gl-draw-arrays-instanced "glDrawArraysInstanced" :void
  ((mode :unsigned-int) (first :int) (count :int) (instance-count :int)))
(define-gl-function gl-draw-elements-instanced "glDrawElementsInstanced" :void
  ((mode :unsigned-int) (count :int) (type :unsigned-int) (indices :pointer) (instance-count :int)))

(define-gl-function gl-gen-textures "glGenTextures" :void ((n :int) (textures :pointer)))
(define-gl-function gl-delete-textures "glDeleteTextures" :void ((n :int) (textures :pointer)))
(define-gl-function gl-active-texture "glActiveTexture" :void ((texture :unsigned-int)))
(define-gl-function gl-bind-texture "glBindTexture" :void ((target :unsigned-int) (texture :unsigned-int)))
(define-gl-function gl-tex-parameter-i "glTexParameteri" :void
  ((target :unsigned-int) (pname :unsigned-int) (param :int)))
(define-gl-function gl-tex-image-2d "glTexImage2D" :void
  ((target :unsigned-int) (level :int) (internal-format :int) (width :int) (height :int)
   (border :int) (format :unsigned-int) (type :unsigned-int) (pixels :pointer)))
(define-gl-function gl-tex-sub-image-2d "glTexSubImage2D" :void
  ((target :unsigned-int) (level :int) (xoffset :int) (yoffset :int) (width :int) (height :int)
   (format :unsigned-int) (type :unsigned-int) (pixels :pointer)))
(define-gl-function gl-generate-mipmap "glGenerateMipmap" :void ((target :unsigned-int)))
(define-gl-function gl-pixel-store-i "glPixelStorei" :void ((pname :unsigned-int) (param :int)))

(define-gl-function gl-gen-framebuffers "glGenFramebuffers" :void ((n :int) (framebuffers :pointer)))
(define-gl-function gl-delete-framebuffers "glDeleteFramebuffers" :void ((n :int) (framebuffers :pointer)))
(define-gl-function gl-bind-framebuffer "glBindFramebuffer" :void ((target :unsigned-int) (framebuffer-id :unsigned-int)))
(define-gl-function gl-check-framebuffer-status "glCheckFramebufferStatus" :unsigned-int ((target :unsigned-int)))
(define-gl-function gl-framebuffer-texture-2d "glFramebufferTexture2D" :void
  ((target :unsigned-int) (attachment :unsigned-int) (textarget :unsigned-int) (texture :unsigned-int) (level :int)))
(define-gl-function gl-blit-framebuffer "glBlitFramebuffer" :void
  ((src-x0 :int) (src-y0 :int) (src-x1 :int) (src-y1 :int)
   (dst-x0 :int) (dst-y0 :int) (dst-x1 :int) (dst-y1 :int)
   (mask :unsigned-int) (filter :unsigned-int)))

(define-gl-function gl-gen-renderbuffers "glGenRenderbuffers" :void ((n :int) (renderbuffers :pointer)))
(define-gl-function gl-delete-renderbuffers "glDeleteRenderbuffers" :void ((n :int) (renderbuffers :pointer)))
(define-gl-function gl-bind-renderbuffer "glBindRenderbuffer" :void ((target :unsigned-int) (renderbuffer-id :unsigned-int)))
(define-gl-function gl-renderbuffer-storage "glRenderbufferStorage" :void
  ((target :unsigned-int) (internal-format :unsigned-int) (width :int) (height :int)))
(define-gl-function gl-framebuffer-renderbuffer "glFramebufferRenderbuffer" :void
  ((target :unsigned-int) (attachment :unsigned-int) (renderbuffer-target :unsigned-int) (renderbuffer-id :unsigned-int)))

(define-gl-function gl-read-pixels "glReadPixels" :void
  ((x :int) (y :int) (width :int) (height :int) (format :unsigned-int) (type :unsigned-int) (data :pointer)))
(define-gl-function gl-get-string "glGetString" :pointer ((name :unsigned-int)))
(define-gl-function gl-get-string-i "glGetStringi" :pointer ((name :unsigned-int) (index :unsigned-int)))
(define-gl-function gl-get-integer-v "glGetIntegerv" :void ((pname :unsigned-int) (data :pointer)))
(define-gl-function gl-get-error "glGetError" :unsigned-int ())

;; Query objects (optional so older contexts can still load the core wrapper)
(define-gl-function gl-gen-queries "glGenQueries" :void ((n :int) (ids :pointer)) :optional t)
(define-gl-function gl-delete-queries "glDeleteQueries" :void ((n :int) (ids :pointer)) :optional t)
(define-gl-function gl-begin-query "glBeginQuery" :void ((target :unsigned-int) (id :unsigned-int)) :optional t)
(define-gl-function gl-end-query "glEndQuery" :void ((target :unsigned-int)) :optional t)
(define-gl-function gl-get-query-object-iv "glGetQueryObjectiv" :void
  ((id :unsigned-int) (pname :unsigned-int) (params :pointer)) :optional t)
(define-gl-function gl-get-query-object-ui64v "glGetQueryObjectui64v" :void
  ((id :unsigned-int) (pname :unsigned-int) (params :pointer)) :optional t)

;; GPU/CPU synchronization
(define-gl-function gl-fence-sync "glFenceSync" :pointer
  ((condition :unsigned-int) (flags :unsigned-int)) :optional t)
(define-gl-function gl-delete-sync "glDeleteSync" :void ((sync :pointer)) :optional t)
(define-gl-function gl-client-wait-sync "glClientWaitSync" :unsigned-int
  ((sync :pointer) (flags :unsigned-int) (timeout :uint64)) :optional t)
(define-gl-function gl-flush "glFlush" :void () :optional t)
(define-gl-function gl-finish "glFinish" :void () :optional t)
