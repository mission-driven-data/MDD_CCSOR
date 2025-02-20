  into _MDD_CCSOR_DirectSups
  from EmployeeSupervisor es
  inner join employees e on  es.supervisor_emp_id= e.emp_id
  where es.is_indirect= 0

  --End