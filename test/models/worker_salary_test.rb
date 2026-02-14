# frozen_string_literal: true

require "test_helper"

class WorkerSalaryTest < ActiveSupport::TestCase
  test "valid worker salary" do
    salary = build(:worker_salary)
    assert salary.valid?
  end

  test "requires gross_monthly_ron" do
    salary = build(:worker_salary, gross_monthly_ron: nil)
    assert_not salary.valid?
  end

  test "gross_monthly_ron must be positive" do
    salary = build(:worker_salary, gross_monthly_ron: -100)
    assert_not salary.valid?
  end

  test "requires effective_from" do
    salary = build(:worker_salary, effective_from: nil)
    assert_not salary.valid?
  end

  test "computes derived_daily_rate_ron on validation" do
    salary = create(:worker_salary, gross_monthly_ron: 5000)
    # 5000 * 12 / 52 / 5 = 230.769230...
    expected = (5000.to_d * 12 / 52 / 5).round(4)
    assert_in_delta expected, salary.derived_daily_rate_ron, 0.01
  end

  test "computes net_monthly_ron using Romanian tax rates" do
    salary = create(:worker_salary, gross_monthly_ron: 5000)

    cas = 5000.to_d * 0.25   # 1250
    cass = 5000.to_d * 0.10  # 500
    taxable = 5000.to_d - cas - cass  # 3250
    income_tax = taxable * 0.10  # 325
    expected_net = 5000.to_d - cas - cass - income_tax  # 2925

    assert_in_delta expected_net, salary.net_monthly_ron, 0.01
  end

  test "recomputes on update" do
    salary = create(:worker_salary, gross_monthly_ron: 5000)
    old_rate = salary.derived_daily_rate_ron

    salary.update!(gross_monthly_ron: 6000)
    assert_not_equal old_rate, salary.derived_daily_rate_ron
  end

  test "soft delete with discard" do
    salary = create(:worker_salary)
    salary.discard
    assert salary.discarded?
  end
end
