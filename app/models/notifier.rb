class Notifier < ActionMailer::Base

  def sample_submission_notification(samples)
    recipients UserProfile.notify_of_new_samples.collect{|x| x.user.email}.join(",")
    from       %("SLIMarray" <slimarray@#{`hostname`.strip}>)
    subject    "[SLIMarray] Microarray samples submitted"
    body       :samples => samples
  end

  def approval_request(samples, emails)
    recipients emails 
    from       %("SLIMarray" <slimarray@#{`hostname`.strip}>)
    subject    "[SLIMarray] Microarray samples need approval"
    body       :samples => samples
  end

  def bioanalyzer_notification(run, ran_by_email, email_recipients)
    recipients email_recipients
    cc         ran_by_email
    from       %("SLIMarray" <slimarray@#{`hostname`.strip}>)
    subject    "[SLIMarray] New Bioanalyzer results"
    body       :run => run, :site_url => SiteConfig.site_url
  end
  
  def qc_outlier_notification(qc_set)
    recipients UserProfile.notify_of_qc_outliers.collect{|x| x.user.email}.join(",")
    from       %("SLIMarray" <slimarray@#{`hostname`.strip}>)
    subject    "[SLIMarray] QC Thresolds exceeded for #{qc_set.hybridization.sample_names}"
    body       :qc_set => qc_set
  end

  def low_inventory_notification(name, needed, available)
    recipients UserProfile.notify_of_low_inventory.collect{|x| x.user.email}.join(",")
    from       %("SLIMarray" <slimarray@#{`hostname`.strip}>)
    subject    "[SLIMarray] Low inventory for #{name}"
    body       :name => name, :needed => needed, :available => available
  end
end
