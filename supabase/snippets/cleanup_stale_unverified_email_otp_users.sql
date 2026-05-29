-- Preview abandoned Email OTP accounts older than 24 hours.
select *
from private.cleanup_stale_unverified_email_otp_users(
  p_older_than => interval '24 hours',
  p_limit => 100,
  p_delete => false
);

-- Delete the same class of accounts after reviewing the preview result.
-- Run this only when you intend to remove the returned auth.users rows.
select *
from private.cleanup_stale_unverified_email_otp_users(
  p_older_than => interval '24 hours',
  p_limit => 100,
  p_delete => true
);
