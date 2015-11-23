(ns office.analysis.sr-by-month
  (:require [office.db.core :as db]
            [office.analysis.data-gatherer :as dg]
            [office.analysis.analytics-board :as ab]))

(defn analyse-data [start-date end-date]
  (let [
        date-query-param {:lower_limit_time start-date
                          :upper_limit_time end-date}
        gen-data (dg/make-gatherers [[db/sr-count-by-month date-query-param {:sr_cnt :booked_count}]
                                     [db/sr-with-activity-state-count-by-month (assoc date-query-param :wia_statuses ["Find Pro OFF"]) {:sr_cnt :fpo_count}]
                                     [db/sr-with-activity-state-count-by-month (assoc date-query-param :wia_statuses ["Find Pro IN"]) {:sr_cnt :fpi_count}]
                                     [db/sr-with-activity-state-count-by-month (assoc date-query-param :wia_statuses ["Find Pro Auto"]) {:sr_cnt :fpa_count}]
                                     [db/sr-with-activity-state-count-by-month (assoc date-query-param :wia_statuses ["Find Pro Auto" "Find Pro IN" "Find Pro OFF"]) {:sr_cnt :fp_count}]])]
    (ab/project-board
      [:booked_count :fpa_count :fpo_count :fpi_count :fp_count]
      (dg/absorb-all-data gen-data))))

(defn get-data-for-nov []
  (analyse-data "2015-11-01" "2015-12-01"))