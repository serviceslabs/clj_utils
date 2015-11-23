(ns office.analysis.sr-by-week-in-msa
  (:require [office.db.core :as db]
            [office.analysis.data-gatherer :as dg]
            [office.analysis.analytics-board :as ab]))

(defn analyse-data [start-date end-date]
  (let [renamer (fn [suffix]
                  {:sr_cnt (keyword (str "booked_" (name suffix)))
                   :gsv (keyword (str "booked_" (name suffix) "_estimate"))})
        date-query-param {:lower_limit_time start-date
                          :upper_limit_time end-date
                          :sr_status "%"
                          :msa_name "%"
                          :wia_status "%"}
        sea-query-params (assoc date-query-param :msa_name "Seattle-Tacoma-Bremerton, WA CMSA")
        cal-query-params (assoc date-query-param :msa_name "San Francisco-Oakland-San Jose, CA CMSA")
        all-gen-data (dg/make-gatherers [[db/sr-count-by-week date-query-param (renamer :all)]
                                         [db/sr-count-by-week-with-activity (merge date-query-param {:wia_status "Order Created"}) (renamer :scheduled_all)]
                                         [db/sr-count-by-week (merge date-query-param {:sr_status "COMPLETED"}) (renamer :completed_all)]
                                         [db/sr-count-by-week sea-query-params (renamer :sea)]
                                         [db/sr-count-by-week-with-activity (merge sea-query-params {:wia_status "Order Created"}) (renamer :scheduled_sea)]
                                         [db/sr-count-by-week (merge sea-query-params {:sr_status "COMPLETED"}) (renamer :completed_sea)]
                                         [db/sr-count-by-week cal-query-params (renamer :cal)]
                                         [db/sr-count-by-week-with-activity (merge cal-query-params {:wia_status "Order Created"}) (renamer :scheduled_cal)]
                                         [db/sr-count-by-week (merge cal-query-params {:sr_status "COMPLETED"}) (renamer :completed_cal)]])]
    (ab/project-board
      [:booked_all :booked_sea :booked_cal
       :booked_all_estimate :booked_sea_estimate :booked_cal_estimate
       :booked_scheduled_all :booked_scheduled_sea :booked_scheduled_cal
       :booked_scheduled_all_estimate :booked_scheduled_sea_estimate :booked_scheduled_cal_estimate
       :booked_completed_all :booked_completed_sea :booked_completed_cal
       :booked_completed_all_estimate :booked_completed_sea_estimate :booked_completed_cal_estimate]
      (dg/absorb-all-data all-gen-data))))