(ns office.db.core
  (:require
    [clojure.java.jdbc :as jdbc]
    [conman.core :as conman]
    [environ.core :refer [env]])
  (:import [java.sql
            BatchUpdateException
            PreparedStatement]))

(defonce ^:dynamic *conn* (atom nil))

(conman/bind-connection *conn* "sql/by_month.sql")
(conman/bind-connection *conn* "sql/by_channel.sql")
(conman/bind-connection *conn* "sql/by_channel_in_msa.sql")
(conman/bind-connection *conn* "sql/by_trade_in_msa.sql")
(conman/bind-connection *conn* "sql/by_week_in_msa.sql")
(conman/bind-connection *conn* "sql/generic_sr_analysis.sql")

(def pool-spec
  {:adapter    :mysql
   :init-size  1
   :min-idle   1
   :max-idle   4
   :max-active 32})

(defn connect! []
  (conman/connect!
    *conn*
   (assoc
     pool-spec
     :jdbc-url (env :database-url))))

(defn disconnect! []
  (conman/disconnect! *conn*))

(defn to-date [sql-date]
  (-> sql-date (.getTime) (java.util.Date.)))

(extend-protocol jdbc/IResultSetReadColumn
  java.sql.Date
  (result-set-read-column [v _ _] (to-date v))

  java.sql.Timestamp
  (result-set-read-column [v _ _] (to-date v)))

(extend-type java.util.Date
  jdbc/ISQLParameter
  (set-parameter [v ^PreparedStatement stmt idx]
    (.setTimestamp stmt idx (java.sql.Timestamp. (.getTime v)))))

(defn load-sql-file [file-path]
  (conman/bind-connection *conn* file-path))
