(ns office.analysis.data-gatherer
  (:require [clojure.set :as set]
            [office.analysis.analytics-board :as board]))

;; Data generators: functions that generate a seq of maps.
(defn make-gatherer [f f-params rename-map]
  (fn []
    (map #(set/rename-keys % rename-map) (f f-params))))

(defn make-gatherers [gen-data]
  (map (partial apply make-gatherer) gen-data))

(defn column-names [one-data-set]
  (->> one-data-set
       first
       keys
       (into #{})))

(defn key-vals [one-data-set k]
  (into #{} (map k one-data-set)))

(defn make-data-board [all-data-sets]
  (let [columns-list (remove empty? (map column-names all-data-sets))
        all-column-names (apply set/union columns-list)
        key-column-name (->> columns-list
                             (apply set/intersection)
                             first)
        _ (println "KEY COLUMN NAME IS - " key-column-name)
        all-key-vals (sort (apply set/intersection (map #(key-vals % key-column-name) all-data-sets)))
        data-columns (disj all-column-names key-column-name)
        my-board (board/make-board all-key-vals data-columns)]
    {:my-board my-board
     :key-column key-column-name
     :data-columns data-columns}))

(defn take-one-data-set [board key-name one-data-set]
  (letfn [(updates-for-a-row [one-row]
                             (let [key-val (key-name one-row)
                                   one-row (dissoc one-row key-name)]
                               (map (fn [[k v]]
                                      [[key-val k] v])
                                    one-row)))]
    (reduce (fn [prev-board [update-pos update-val]]
              (assoc-in prev-board update-pos update-val))
            board
            (mapcat updates-for-a-row one-data-set))))

(defn make-data-board-set [{:keys [my-board key-column data-columns]} all-data-sets]
  (reduce (fn [prev-board one-data-set]
            (take-one-data-set prev-board key-column one-data-set))
          my-board
          all-data-sets))

(defn absorb-all-data [generators]
  (let [all-data-set (map (fn [f] (f)) generators)
        my-board-detail (make-data-board all-data-set)
        result (make-data-board-set my-board-detail all-data-set)]
    result))
