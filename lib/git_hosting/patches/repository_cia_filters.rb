module GitHosting
	module Patches
		module RepositoryCiaFilters
			module FilterMethods
				def notified(scmid)
					scmid = scmid.scmid if scmid.instance_of?(Changeset)
					#self.cia_notifications.push GitCiaNotification.new(:scmid => scmid)
					self.push GitCiaNotification.new(:scmid => scmid)
				end

				def notified?(scmid)
					#GitHosting.logger.debug "1On has_notified? processing smcid: #{scmid}"
					scmid = scmid.scmid if scmid.instance_of?(Changeset)
					#GitHosting.logger.debug "2On has_notified? processing smcid: #{scmid}"
					#q = find(:first, :conditions => ["scmid = ?", scmid])
					#GitHosting.logger.debug "Query result: #{q}, NIL? #{q.nil?}"
					#return !q.nil?
					#return !self.cia_notifications.find(:first, :conditions => ["scmid = ?", scmid_]).nil?
					return !find(:first, :conditions => ["scmid = ?", scmid]).nil?
				end
			end
			def self.included(base)
				base.class_eval do
					unloadable
				end
				base.extend(FilterMethods)
			end
		end
	end
end

