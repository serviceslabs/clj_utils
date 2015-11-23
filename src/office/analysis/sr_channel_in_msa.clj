(ns office.analysis.sr-channel-in-msa
  (:require [office.db.core :as db]
            [office.analysis.analytics-board :as board]))

(def data-details [[:booked                 db/sr-booked-count-in-msa]
                   [:fixed-price            db/fixed-price-sr-booked-count-in-msa]
                   [:booked-and-scheduled   db/sr-booked-that-were-scheduled-in-msa]
                   [:booked-and-completed   db/sr-booked-that-were-completed-in-msa]
                   [:only-scheduled         db/sr-scheduled-in-given-time-in-msa]
                   [:only-completed         db/sr-completed-in-given-time-in-msa]])

(defn get-channel-analytics-for-msa [lower-time-limit upper-time-limit msa-name]
  (let [query-params {:lower_limit_time (str lower-time-limit)
                      :upper_limit_time (str upper-time-limit)
                      :msa_name         msa-name}
        channel-names (into #{} (map :channel (db/sr-channels query-params)))
        channel-details (map first data-details)
        channel-detail-fns (map second data-details)
        empty-result-board (board/make-board channel-names channel-details)
        board-data ((apply juxt channel-detail-fns) query-params)
        result-details (map vector (iterate inc 0) channel-details)
        filled-board (reduce (fn [old-board [i data-name]]
                               (board/update-col old-board data-name (board-data i) :channel :count))
                             empty-result-board
                             result-details)]
    (board/project-board channel-details filled-board)))
