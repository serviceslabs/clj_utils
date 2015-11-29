(ns office.analysis.generic-analysis
  (:require [office.db.core :as db]
            [clojure.pprint :as pp]))

(def all-msas ["%" "Seattle-Tacoma-Bremerton, WA CMSA" "San Francisco-Oakland-San Jose, CA CMSA"])

(defn- print-query-result [f query-param]
  (map (fn [q]
         (println (str "Query params:" q))
         (pp/print-table (f q))) query-param))

(defn get-data-for-interval [start-date end-date]
  (let [msa-names ["%" "Seattle-Tacoma-Bremerton, WA CMSA" "San Francisco-Oakland-San Jose, CA CMSA"]
        sr-statuses ["%" "COMPLETED"]
        wia-statuses [".*" "Order Created"]
        ;wia-statuses ["^Find Pro (Auto|IN|OFF)$"]
        query-param (for [msa msa-names
                          sr-status sr-statuses
                          wia wia-statuses
                          :when (not (and (= wia "Order Created") (= sr-status "COMPLETED")))]
                      {:msa_name msa
                       :sr_status sr-status
                       :wia_status (str "^" wia "$")
                       :lower_limit_time start-date
                       :upper_limit_time end-date
                       :default_estimate 120})]
    (map (fn [q]
           (println (str "Query params:" q))
           (pp/print-table (db/generic-sr-count-and-gsv q))) query-param)))

(defn get-pro-sourcing-data [start-date end-date]
  (let [wia1-statuses ["Find Pro Auto" "Find Pro OFF" "Find Pro IN" "Find Pro (Auto|OFF|IN)"]
        wia2-statuses ["Order Created" "Order Completed"]
        query-param (for [msa all-msas
                          wia1 wia1-statuses
                          wia2 wia2-statuses]
                      {:msa_name msa
                       :sr_status "%"
                       :wia1_status_regex (str "^" wia1 "$")
                       :wia2_status_regex (str "^" wia2 "$")
                       :lower_limit_time start-date
                       :upper_limit_time end-date
                       :default_estimate 120})]
    (print-query-result db/generic-sr-count-and-gsv-with-history query-param)))

(defn first-booked-time-details [start-date end-date]
  (let [msa-names ["%" "Seattle-Tacoma-Bremerton, WA CMSA" "San Francisco-Oakland-San Jose, CA CMSA"]
        query-param (for [msa msa-names]
                      {:msa_name msa
                       :sr_status "%"
                       :wia_status "^$"
                       :lower_limit_time start-date
                       :upper_limit_time end-date
                       :default_estimate 120})]
    (map (fn [q]
           (println (str "Query params:" q))
           (pp/print-table (db/generic-sr-count-and-gsv-by-first-scheduled-time q))) query-param)))

(defn completed-time-details [start-date end-date]
  (let [msa-names ["%" "Seattle-Tacoma-Bremerton, WA CMSA" "San Francisco-Oakland-San Jose, CA CMSA"]
        query-param (for [msa msa-names]
                      {:msa_name msa
                       :lower_limit_time start-date
                       :upper_limit_time end-date
                       :default_estimate 120})]
    (map (fn [q]
           (println (str "Query params:" q))
           (pp/print-table (db/count-completed-srs q))) query-param)))

