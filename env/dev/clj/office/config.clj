(ns office.config
  (:require [selmer.parser :as parser]
            [taoensso.timbre :as timbre]
            [office.dev-middleware :refer [wrap-dev]]))

(def defaults
  {:init
   (fn []
     (parser/cache-off!)
     (timbre/info "\n-=[office started successfully using the development profile]=-"))
   :middleware wrap-dev})
