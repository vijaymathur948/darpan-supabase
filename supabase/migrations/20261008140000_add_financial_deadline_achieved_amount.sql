alter table public.financial_deadlines
  add column achieved_amount numeric(12, 2),
  add constraint financial_deadlines_achieved_amount_nonnegative
    check (achieved_amount is null or achieved_amount >= 0);
