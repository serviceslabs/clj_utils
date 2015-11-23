-- name: sr-created-count
-- List the count of SRs by trades in the given MSA that were created on the given time interval
select sku_trade_map.trade_name, count(distinct(po.partial_order_id)) sr_count
from customer_order_service_production.partial_orders po
inner join magic_list_prod.magic_list_items mli
on po.magic_list_id=mli.magic_list_id
inner join customer_order_service_production.msa_mappings mm
on po.zipcode = mm.zip
and mm.msa_name like :msa_name
and (is_test is null or is_test=false)
inner join (
  select sk1.sku_id, et.trade_id, tr.trade_name
  from catalog_prod.skus sk1
  inner join (
             select sk.sku_id, et.estimate_id, min(et.display_order) primary_estimate
                    from catalog_prod.skus sk
                    inner join catalog_prod.estimate_trades et
                    on sk.initial_estimate_id=et.estimate_id
                    and et.deleted=false
                    group by sk.sku_id, et.estimate_id
                    ) sk2
  on sk1.sku_id=sk2.sku_id
  inner join catalog_prod.estimate_trades et
  on sk1.initial_estimate_id=et.estimate_id
  and et.deleted=false
  and sk2.estimate_id=et.estimate_id
  and sk2.primary_estimate=et.display_order
  inner join catalog_prod.trades tr
  on et.trade_id=tr.trade_id
) sku_trade_map
on sku_trade_map.sku_id= mli.sku_id
where po.partial_order_id in (
  select distinct(wi.associated_id) sr_ids
  from workflow_service_production.work_items wi
  where wi.status != 'Excluded'
  and wi.created_time > :lower_limit_time
  and wi.created_time < :upper_limit_time
)
group by sku_trade_map.trade_name
order by trade_name asc


-- name: trade-sr-count
-- List the count of SRs in the given MSA that went into a specific state
select sku_trade_map.trade_name, count(distinct(po.partial_order_id)) sr_count
from customer_order_service_production.partial_orders po
inner join magic_list_prod.magic_list_items mli
on po.magic_list_id=mli.magic_list_id
and po.partial_order_status like :sr_status
inner join customer_order_service_production.msa_mappings mm
on po.zipcode = mm.zip
and mm.msa_name like :msa_name
and (is_test is null or is_test=false)
inner join (
  select sk1.sku_id, et.trade_id, tr.trade_name
  from catalog_prod.skus sk1
  inner join (
             select sk.sku_id, et.estimate_id, min(et.display_order) primary_estimate
                    from catalog_prod.skus sk
                    inner join catalog_prod.estimate_trades et
                    on sk.initial_estimate_id=et.estimate_id
                    and et.deleted=false
                    group by sk.sku_id, et.estimate_id
                    ) sk2
  on sk1.sku_id=sk2.sku_id
  inner join catalog_prod.estimate_trades et
  on sk1.initial_estimate_id=et.estimate_id
  and et.deleted=false
  and sk2.estimate_id=et.estimate_id
  and sk2.primary_estimate=et.display_order
  inner join catalog_prod.trades tr
  on et.trade_id=tr.trade_id
) sku_trade_map
on sku_trade_map.sku_id= mli.sku_id
where po.partial_order_id in (
  select distinct(wi.associated_id) sr_ids
  from workflow_service_production.work_items wi
  inner join workflow_service_production.work_item_activities wia
  on wi.work_item_id=wia.work_item_id
  and wi.status != 'Excluded'
  and wia.status REGEXP :wia_status
  and wi.created_time > :lower_limit_time
  and wi.created_time < :upper_limit_time
)
group by sku_trade_map.trade_name
order by trade_name asc

-- name: trade-sr-count-in-two-states
-- List the count of SRs in the given MSA that went into a specific state
select sku_trade_map.trade_name, count(distinct(po.partial_order_id)) sr_count
from customer_order_service_production.partial_orders po
inner join magic_list_prod.magic_list_items mli
on po.magic_list_id=mli.magic_list_id
inner join customer_order_service_production.msa_mappings mm
on po.zipcode = mm.zip
and mm.msa_name like :msa_name
and (is_test is null or is_test=false)
inner join (
  select sk1.sku_id, et.trade_id, tr.trade_name
  from catalog_prod.skus sk1
  inner join (
             select sk.sku_id, et.estimate_id, min(et.display_order) primary_estimate
                    from catalog_prod.skus sk
                    inner join catalog_prod.estimate_trades et
                    on sk.initial_estimate_id=et.estimate_id
                    and et.deleted=false
                    group by sk.sku_id, et.estimate_id
                    ) sk2
  on sk1.sku_id=sk2.sku_id
  inner join catalog_prod.estimate_trades et
  on sk1.initial_estimate_id=et.estimate_id
  and et.deleted=false
  and sk2.estimate_id=et.estimate_id
  and sk2.primary_estimate=et.display_order
  inner join catalog_prod.trades tr
  on et.trade_id=tr.trade_id
) sku_trade_map
on sku_trade_map.sku_id= mli.sku_id
where po.partial_order_id in (
  select distinct(wi.associated_id) sr_ids
  from workflow_service_production.work_items wi
  inner join workflow_service_production.work_item_activities wia1
  on wi.work_item_id=wia1.work_item_id
  and wi.status != 'Excluded'
  inner join workflow_service_production.work_item_activities wia2
  on wia2.work_item_id=wi.work_item_id
  and wia1.created_time < wia2.created_time
  and wia1.work_item_activity_id != wia2.work_item_activity_id
  and wia1.status REGEXP :first_status
  and wia2.status REGEXP :second_status
  and wi.created_time > :lower_limit_time
  and wi.created_time < :upper_limit_time
)
group by sku_trade_map.trade_name
order by trade_name asc
