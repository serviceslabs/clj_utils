(ns office.analysis.sr-trade-in-msa
  (:require [office.db.core :as db]
            [office.analysis.analytics-board :as board]
            [clojure.pprint :as pp]))

(defn filter-only-required [rows]
  (filter
    (fn [row]
      (contains?
        #{"Handyman" "General Contracting"
          "Painting" "Plumbing"
          "Electrical - High Voltage"
          "Flooring"} (:trade_name row)))
    rows))

(defn trade-data [lower-time-limit upper-time-limit]
  (let [sr-status-all  ["%" "COMPLETED"]
        msa-name-all   ["%" "Seattle-Tacoma-Bremerton, WA CMSA" "San Francisco-Oakland-San Jose, CA CMSA"]
        wia-status-all ["^Find Pro Auto$" "^Find Pro IN$" "^Find Pro OFF$" "^Find Pro (Auto|IN|OFF)$"]
        all-inputs (for [s sr-status-all
                         msa msa-name-all
                         wia-status wia-status-all]
                     {:sr_status s :msa_name msa :wia_status wia-status
                      :lower_limit_time lower-time-limit :upper_limit_time upper-time-limit})]
    (map (fn [d]
           {:data d
            :result (filter-only-required (db/trade-sr-count d))})
         all-inputs)))

(defn accepted-data [lower-time-limit upper-time-limit]
  (let [msa-name-all     ["%" "Seattle-Tacoma-Bremerton, WA CMSA" "San Francisco-Oakland-San Jose, CA CMSA"]
        first-status-all ["^Find Pro Auto$" "^Find Pro IN$" "^Find Pro OFF$" "^Find Pro (Auto|IN|OFF)$"]
        second-status-all ["^Order Created$"]
        all-inputs (for [msa msa-name-all
                         first-status first-status-all
                         second-status second-status-all]
                     {:msa_name msa :first_status first-status :second_status second-status
                      :lower_limit_time lower-time-limit :upper_limit_time upper-time-limit})]
    (pmap (fn [d]
           {:data d
            :result (filter-only-required (db/trade-sr-count-in-two-states d))})
         all-inputs)))

(defn print-one-result [r]
  (println "Query" (:data r))
  (pp/print-table (:result r)))

(defn created-data [lower-time-limit upper-time-limit]
  (let [msa-name-all     ["%" "Seattle-Tacoma-Bremerton, WA CMSA" "San Francisco-Oakland-San Jose, CA CMSA"]
        all-inputs (for [msa msa-name-all]
                     {:msa_name msa :lower_limit_time lower-time-limit :upper_limit_time upper-time-limit})]
    (pmap (fn [d]
            {:data d
             :result (filter-only-required (db/sr-created-count d))})
          all-inputs)))
