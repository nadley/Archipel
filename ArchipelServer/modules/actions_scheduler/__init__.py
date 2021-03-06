#!/usr/bin/python
import actionscheduler
import archipel


ARCHIPEL_NS_ENTITY_SCHEDULER = "archipel:entity:scheduler"

# this method will be call at loading
def __module_init__actions_scheduler(self):
    dbfile = self.configuration.get("SCHEDULER", "database");
    self.actions_scheduler = actionscheduler.TNActionScheduler(self, dbfile)

# this method will be called at registration of handlers for XMPP
def __module_register_stanza__actions_scheduler(self):
    self.xmppclient.RegisterHandler('iq', self.actions_scheduler.process_iq, ns=ARCHIPEL_NS_ENTITY_SCHEDULER)


# finally, we add the methods to the class
setattr(archipel.TNArchipelVirtualMachine, "__module_init__actions_scheduler", __module_init__actions_scheduler)
setattr(archipel.TNArchipelVirtualMachine, "__module_register_stanza__actions_scheduler", __module_register_stanza__actions_scheduler)

setattr(archipel.TNArchipelHypervisor, "__module_init__actions_scheduler", __module_init__actions_scheduler)
setattr(archipel.TNArchipelHypervisor, "__module_register_stanza__actions_scheduler", __module_register_stanza__actions_scheduler)