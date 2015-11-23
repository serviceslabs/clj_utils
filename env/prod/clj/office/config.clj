(ns office.config
  (:require [taoensso.timbre :as timbre]))

(def defaults
  {:init
   (fn []
     (timbre/info "\n-=[office started successfully]=-"))
   :middleware identity})
