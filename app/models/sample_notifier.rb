class SampleNotifier < ActionMailer::Base

  def submission_notification(samples)
    recipients SiteConfig.administrator_email
    from       %("SLIMarray" <slimarray@#{`hostname`.strip}>)
    subject    "[SLIMarray] Samples recorded"
    body       :samples => samples
  end
  
end
