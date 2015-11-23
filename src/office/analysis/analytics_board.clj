(ns office.analysis.analytics-board
  (:require [clojure.pprint :as pp]))

(defn make-board [row-keys col-keys]
  (let [one-row (zipmap col-keys (repeat 0))]
    (zipmap row-keys (repeat one-row))))

(defn update-col [board col-name data-updates key-fn val-fn]
  (let [update-details (map (fn [this-data]
                              [(key-fn this-data) (val-fn this-data)]) data-updates)]
    (reduce (fn [board [row-name row-col-val]]
              (assoc-in board [row-name col-name] row-col-val))
            board
            update-details)))

(defn push-board-row-keys [board]
  (sort-by :row-key (map #(assoc (second %) :row-key (first %)) board)))

(defn project-board
  ([board]
   (pp/print-table (push-board-row-keys board)))
  ([ks board]
   (pp/print-table (conj (seq ks) :row-key)
                   (push-board-row-keys board))))