/*
 * TNViewHypervisorControl.j
 *
 * Copyright (C) 2010 Antoine Mercadal <antoine.mercadal@inframonde.eu>
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>
@import <AppKit/CPCollectionView.j>

@import "TNNetworkObject.j"
@import "TNDHCPEntryObject.j"
@import "TNNetworkController.j"

TNArchipelPushNotificationNetworks          = @"archipel:push:network";
TNArchipelTypeHypervisorNetwork             = @"archipel:hypervisor:network";
TNArchipelTypeHypervisorNetworkGet          = @"get";
TNArchipelTypeHypervisorNetworkDefine       = @"define";
TNArchipelTypeHypervisorNetworkUndefine     = @"undefine";
TNArchipelTypeHypervisorNetworkCreate       = @"create";
TNArchipelTypeHypervisorNetworkDestroy      = @"destroy";


/*! @defgroup  hypervisornetworks Module Hypervisor Networks
    @desc This manages hypervisors' virtual networks
*/

/*! @ingroup hypervisornetworks
    The main module controller
*/
@implementation TNHypervisorNetworksController : TNModule
{
    @outlet CPButtonBar                 buttonBarControl;
    @outlet CPScrollView                scrollViewNetworks;
    @outlet CPSearchField               fieldFilterNetworks;
    @outlet CPTextField                 fieldJID;
    @outlet CPTextField                 fieldName;
    @outlet CPView                      viewTableContainer;
    @outlet TNNetworkController         networkController;

    CPButton                            _activateButton;
    CPButton                            _deactivateButton;
    CPButton                            _editButton;
    CPButton                            _minusButton;
    CPButton                            _plusButton;
    CPTableView                         _tableViewNetworks;
    TNTableViewDataSource               _datasourceNetworks;
}

#pragma mark -
#pragma mark Initialization

/*! called at cib awaking
*/
- (void)awakeFromCib
{
    [fieldJID setSelectable:YES];

    [viewTableContainer setBorderedWithHexColor:@"#C0C7D2"];

    /* VM table view */
    _datasourceNetworks     = [[TNTableViewDataSource alloc] init];
    _tableViewNetworks      = [[CPTableView alloc] initWithFrame:[scrollViewNetworks bounds]];

    [scrollViewNetworks setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [scrollViewNetworks setAutohidesScrollers:YES];
    [scrollViewNetworks setDocumentView:_tableViewNetworks];


    [_tableViewNetworks setUsesAlternatingRowBackgroundColors:YES];
    [_tableViewNetworks setAutoresizingMask: CPViewWidthSizable | CPViewHeightSizable];
    [_tableViewNetworks setAllowsColumnResizing:YES];
    [_tableViewNetworks setAllowsEmptySelection:YES];
    [_tableViewNetworks setAllowsMultipleSelection:YES];
    [_tableViewNetworks setTarget:self];
    [_tableViewNetworks setDelegate:self];
    [_tableViewNetworks setDoubleAction:@selector(editNetwork:)];

    var columNetworkEnabled = [[CPTableColumn alloc] initWithIdentifier:@"icon"],
        imgView = [[CPImageView alloc] initWithFrame:CGRectMake(0,0,16,16)],
        columNetworkName = [[CPTableColumn alloc] initWithIdentifier:@"networkName"],
        columBridgeName = [[CPTableColumn alloc] initWithIdentifier:@"bridgeName"],
        columForwardMode = [[CPTableColumn alloc] initWithIdentifier:@"bridgeForwardMode"],
        columForwardDevice = [[CPTableColumn alloc] initWithIdentifier:@"bridgeForwardDevice"],
        columBridgeIP = [[CPTableColumn alloc] initWithIdentifier:@"bridgeIP"],
        columBridgeNetmask = [[CPTableColumn alloc] initWithIdentifier:@"bridgeNetmask"];


    [imgView setImageScaling:CPScaleNone];
    [columNetworkEnabled setDataView:imgView];
    [columNetworkEnabled setWidth:16];
    [[columNetworkEnabled headerView] setStringValue:@""];

    [[columNetworkName headerView] setStringValue:@"Name"];
    [columNetworkName setWidth:250];
    [columNetworkName setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"networkName" ascending:YES]];

    [[columBridgeName headerView] setStringValue:@"Bridge"];
    [columBridgeName setWidth:80];
    [columBridgeName setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"bridgeName" ascending:YES]];

    [[columForwardMode headerView] setStringValue:@"Forward Mode"];
    [columForwardMode setWidth:120];
    [columForwardMode setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"bridgeForwardMode" ascending:YES]];

    [[columForwardDevice headerView] setStringValue:@"Forward Device"];
    [columForwardDevice setWidth:120];
    [columForwardDevice setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"bridgeForwardDevice" ascending:YES]];

    [[columBridgeIP headerView] setStringValue:@"Bridge IP"];
    [columBridgeIP setWidth:90];
    [columBridgeIP setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"bridgeIP" ascending:YES]];

    [[columBridgeNetmask headerView] setStringValue:@"Bridge Netmask"];
    [columBridgeNetmask setWidth:150];
    [columBridgeNetmask setSortDescriptorPrototype:[CPSortDescriptor sortDescriptorWithKey:@"bridgeNetmask" ascending:YES]];

    [_tableViewNetworks addTableColumn:columNetworkEnabled];
    [_tableViewNetworks addTableColumn:columNetworkName];
    [_tableViewNetworks addTableColumn:columBridgeName];
    [_tableViewNetworks addTableColumn:columForwardMode];
    [_tableViewNetworks addTableColumn:columForwardDevice];
    [_tableViewNetworks addTableColumn:columBridgeIP];
    [_tableViewNetworks addTableColumn:columBridgeNetmask];

    [_datasourceNetworks setTable:_tableViewNetworks];
    [_datasourceNetworks setSearchableKeyPaths:[@"networkName", @"bridgeName", @"bridgeForwardMode", @"bridgeForwardDevice", @"bridgeIP", @"bridgeNetmask"]];

    [fieldFilterNetworks setTarget:_datasourceNetworks];
    [fieldFilterNetworks setAction:@selector(filterObjects:)];

    [_tableViewNetworks setDataSource:_datasourceNetworks];
    [_tableViewNetworks setDelegate:self];

    [networkController setDelegate:self];

    var menu = [[CPMenu alloc] init];
    [menu addItemWithTitle:@"Create new virtual network" action:@selector(addNetwork:) keyEquivalent:@""];
    [menu addItem:[CPMenuItem separatorItem]];
    [menu addItemWithTitle:@"Edit" action:@selector(editNetwork:) keyEquivalent:@""];
    [menu addItemWithTitle:@"Activate" action:@selector(activateNetwork:) keyEquivalent:@""];
    [menu addItemWithTitle:@"Deactivate" action:@selector(deactivateNetwork:) keyEquivalent:@""];
    [menu addItem:[CPMenuItem separatorItem]];
    [menu addItemWithTitle:@"Delete" action:@selector(delNetwork:) keyEquivalent:@""];
    [_tableViewNetworks setMenu:menu];

    _plusButton = [CPButtonBar plusButton];
    [_plusButton setTarget:self];
    [_plusButton setAction:@selector(addNetwork:)];

    _minusButton = [CPButtonBar minusButton];
    [_minusButton setTarget:self];
    [_minusButton setAction:@selector(delNetwork:)];

    _activateButton = [CPButtonBar plusButton];
    [_activateButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/check.png"] size:CPSizeMake(16, 16)]];
    [_activateButton setTarget:self];
    [_activateButton setAction:@selector(activateNetwork:)];

    _deactivateButton = [CPButtonBar plusButton];
    [_deactivateButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/cancel.png"] size:CPSizeMake(16, 16)]];
    [_deactivateButton setTarget:self];
    [_deactivateButton setAction:@selector(deactivateNetwork:)];

    _editButton  = [CPButtonBar plusButton];
    [_editButton setImage:[[CPImage alloc] initWithContentsOfFile:[[CPBundle mainBundle] pathForResource:@"IconsButtons/edit.png"] size:CPSizeMake(16, 16)]];
    [_editButton setTarget:self];
    [_editButton setAction:@selector(editNetwork:)];

    [_minusButton setEnabled:NO];
    [_activateButton setEnabled:NO];
    [_deactivateButton setEnabled:NO];
    [_editButton setEnabled:NO];

    [buttonBarControl setButtons:[_plusButton, _minusButton, _editButton, _activateButton, _deactivateButton]];

    [networkController setTableNetwork:_tableViewNetworks];
}


#pragma mark -
#pragma mark TNModule overrides

/*! called when module is loaded
*/
- (void)willLoad
{
    [super willLoad];

    var center = [CPNotificationCenter defaultCenter];

    [center addObserver:self selector:@selector(_didUpdateNickName:) name:TNStropheContactNicknameUpdatedNotification object:[self entity]];
    [center addObserver:self selector:@selector(_didTableSelectionChange:) name:CPTableViewSelectionDidChangeNotification object:_tableViewNetworks];
    [center postNotificationName:TNArchipelModulesReadyNotification object:self];

    [_tableViewNetworks setDelegate:nil];
    [_tableViewNetworks setDelegate:self]; // hum....

    [self registerSelector:@selector(_didReceivePush:) forPushNotificationType:TNArchipelPushNotificationNetworks];
    [self getHypervisorNetworks];
}

/*! called when module becomes visible
*/
- (void)willShow
{
    [super willShow];

    [fieldName setStringValue:[[self entity] nickname]];
    [fieldJID setStringValue:[[self entity] JID]];
}

/*! called when MainMenu is ready
*/
- (void)menuReady
{
    [[_menu addItemWithTitle:@"Create new virtual network" action:@selector(addNetwork:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:@"Edit selected network" action:@selector(editNetwork:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:@"Delete selected network" action:@selector(delNetwork:) keyEquivalent:@""] setTarget:self];
    [_menu addItem:[CPMenuItem separatorItem]];
    [[_menu addItemWithTitle:@"Activate this network" action:@selector(activateNetwork:) keyEquivalent:@""] setTarget:self];
    [[_menu addItemWithTitle:@"Deactivate this network" action:@selector(deactivateNetwork:) keyEquivalent:@""] setTarget:self];
}

/*! called when permissions changes
*/
- (void)permissionsChanged
{
    [self setControl:_plusButton enabledAccordingToPermission:@"network_define"];
    [self setControl:_minusButton enabledAccordingToPermission:@"network_undefine"];
    [self setControl:_editButton enabledAccordingToPermission:@"network_define"];
    [self setControl:_activateButton enabledAccordingToPermission:@"network_create"];
    [self setControl:_deactivateButton enabledAccordingToPermission:@"network_destroy"];

    [self _didTableSelectionChange:nil];
}


#pragma mark -
#pragma mark Notification handlers

/*! called when entity's name has change
    @param aNotification the notification
*/
- (void)_didUpdateNickName:(CPNotification)aNotification
{
    if ([aNotification object] == [self entity])
    {
       [fieldName setStringValue:[[self entity] nickname]]
    }
}

/*! called when an Archipel push is recieved
    @param somePushInfo CPDictionary containing push information
*/
- (BOOL)_didReceivePush:(CPDictionary)somePushInfo
{
    var sender  = [somePushInfo objectForKey:@"owner"],
        type    = [somePushInfo objectForKey:@"type"],
        change  = [somePushInfo objectForKey:@"change"],
        date    = [somePushInfo objectForKey:@"date"];

    CPLog.info(@"PUSH NOTIFICATION: from: " + sender + ", type: " + type + ", change: " + change);

    [self getHypervisorNetworks];
    return YES;
}

/*! triggered when the main table selection changes. it will update GUI
*/
- (void)_didTableSelectionChange:(CPNotification)aNotification
{
    var selectedIndex   = [[_tableViewNetworks selectedRowIndexes] firstIndex];

    [_minusButton setEnabled:NO];
    [_editButton setEnabled:NO];
    [_activateButton setEnabled:NO];
    [_deactivateButton setEnabled:NO];

    if ([_tableViewNetworks numberOfSelectedRows] == 0)
        return;

    var networkObject   = [_datasourceNetworks objectAtIndex:selectedIndex];

    if ([networkObject isNetworkEnabled])
    {
        [self setControl:_deactivateButton enabledAccordingToPermission:@"network_destroy"];
    }
    else
    {
        [self setControl:_minusButton enabledAccordingToPermission:@"network_undefine"];
        [self setControl:_editButton enabledAccordingToPermission:@"network_define"];
        [self setControl:_activateButton enabledAccordingToPermission:@"network_create"];
    }

    return YES;
}


#pragma mark -
#pragma mark Utilities

/*! Generate a stanza containing libvirt valid network description
    @param anUid the ID to use for the stanza
    @return ready to send generate stanza
*/
- (TNStropheStanza)generateXMLNetworkStanzaWithUniqueID:(id)anUid
{
    var selectedIndex   = [[_tableViewNetworks selectedRowIndexes] firstIndex];

    if (selectedIndex == -1)
        return

    var networkObject   = [_datasourceNetworks objectAtIndex:selectedIndex],
        stanza          = [TNStropheStanza iqWithAttributes:{"type": "set", "id": anUid}];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorNetwork}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorNetworkDefine}];

    [stanza addChildWithName:@"network"];

    [stanza addChildWithName:@"name"];
    [stanza addTextNode:[networkObject networkName]];
    [stanza up];

    [stanza addChildWithName:@"uuid"];
    [stanza addTextNode:[networkObject UUID]];
    [stanza up];

    [stanza addChildWithName:@"forward" andAttributes:{"mode": [networkObject bridgeForwardMode], "dev": [networkObject bridgeForwardDevice]}];
    [stanza up];

    [stanza addChildWithName:@"bridge" andAttributes:{"name": [networkObject bridgeName], "stp": ([networkObject isSTPEnabled]) ? "on" :"off", "delay": [networkObject bridgeDelay]}];
    [stanza up];

    [stanza addChildWithName:@"ip" andAttributes:{"address": [networkObject bridgeIP], "netmask": [networkObject bridgeNetmask]}];

    var dhcp = [networkObject isDHCPEnabled];
    if (dhcp)
    {
        [stanza addChildWithName:@"dhcp"];

        var DHCPRangeEntries = [networkObject DHCPEntriesRanges];

        for (var i = 0; i < [DHCPRangeEntries count]; i++)
        {
            var DHCPEntry = [DHCPRangeEntries objectAtIndex:i];

            [stanza addChildWithName:@"range" andAttributes:{"start" : [DHCPEntry start], "end": [DHCPEntry end]}];
            [stanza up];
        }

        var DHCPHostsEntries = [networkObject DHCPEntriesHosts];

        for (var i = 0; i < [DHCPHostsEntries count]; i++)
        {
            var DHCPEntry = [DHCPHostsEntries objectAtIndex:i];

            [stanza addChildWithName:@"host" andAttributes:{"mac" : [DHCPEntry mac], "name": [DHCPEntry name], "ip": [DHCPEntry IP]}];
            [stanza up];
        }

        [stanza up];
    }

    [stanza up];

    return stanza;
}

/*! generate a random MAC Address
    @return CPString containing a random mac address
*/
- (CPString)generateIPForNewNetwork
{
    var dA      = Math.round(Math.random() * 255),
        dB      = Math.round(Math.random() * 255);

    return dA + "." + dB + ".0.1";
}

#pragma mark -
#pragma mark XMPP Controls

/*! asks networks to the hypervisor
*/
- (void)getHypervisorNetworks
{
    var stanza  = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorNetwork}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorNetworkGet}];

    [self sendStanza:stanza andRegisterSelector:@selector(_didReceiveHypervisorNetworks:)];
}

/*! compute the answer containing the network information
*/
- (void)_didReceiveHypervisorNetworks:(id)aStanza
{
    if ([aStanza type] == @"result")
    {
        var activeNetworks      = [[aStanza firstChildWithName:@"activedNetworks"] children],
            unactiveNetworks    = [[aStanza firstChildWithName:@"unactivedNetworks"] children],
            allNetworks         = [CPArray array];

        [allNetworks addObjectsFromArray:activeNetworks];
        [allNetworks addObjectsFromArray:unactiveNetworks];

        [_datasourceNetworks removeAllObjects];

        for (var i = 0; i < [allNetworks count]; i++)
        {
            var network                 = [allNetworks objectAtIndex:i],
                name                    = [[network firstChildWithName:@"name"] text],
                uuid                    = [[network firstChildWithName:@"uuid"] text],
                bridge                  = [network firstChildWithName:@"bridge"],
                bridgeName              = [bridge valueForAttribute:@"name"],
                bridgeSTP               = ([bridge valueForAttribute:@"stp"] == @"on") ? YES : NO,
                bridgeDelay             = [bridge valueForAttribute:@"forwardDelay"],
                forward                 = [network firstChildWithName:@"forward"],
                forwardMode             = [forward valueForAttribute:@"mode"],
                forwardDev              = [forward valueForAttribute:@"dev"],
                ip                      = [network firstChildWithName:@"ip"],
                bridgeIP                = [ip valueForAttribute:@"address"],
                bridgeNetmask           = [ip valueForAttribute:@"netmask"],
                dhcp                    = [ip firstChildWithName:@"dhcp"],
                DHCPEnabled             = (dhcp) ? YES : NO,
                DHCPRangeEntries        = [dhcp childrenWithName:@"range"],
                DHCPHostEntries         = [dhcp childrenWithName:@"host"],
                networkActive           = [activeNetworks containsObject:network],
                DHCPRangeEntriesArray   = [CPArray array],
                DHCPHostEntriesArray    = [CPArray array];

            for (var j = 0; DHCPEnabled && j < [DHCPRangeEntries count]; j++)
            {
                var DHCPEntry           = [DHCPRangeEntries objectAtIndex:j],
                    randgeStartAddr     = [DHCPEntry valueForAttribute:@"start"],
                    rangeEndAddr        = [DHCPEntry valueForAttribute:@"end"],
                    DHCPEntryObject     = [TNDHCPEntry DHCPRangeWithStartAddress:randgeStartAddr endAddress:rangeEndAddr];

                [DHCPRangeEntriesArray addObject:DHCPEntryObject];
            }

            for (var j = 0; DHCPEnabled && j < [DHCPHostEntries count]; j++)
            {
                var DHCPEntry       = [DHCPHostEntries objectAtIndex:j],
                    hostsMac        = [DHCPEntry valueForAttribute:@"mac"],
                    hostName        = [DHCPEntry valueForAttribute:@"name"],
                    hostIP          = [DHCPEntry valueForAttribute:@"ip"],
                    DHCPEntryObject = [TNDHCPEntry DHCPHostWithMac:hostsMac name:hostName ip:hostIP];

                [DHCPHostEntriesArray addObject:DHCPEntryObject];
            }

            var newNetwork  = [TNNetwork networkWithName:name
                                                    UUID:uuid
                                              bridgeName:bridgeName
                                             bridgeDelay:bridgeDelay
                                       bridgeForwardMode:forwardMode
                                     bridgeForwardDevice:forwardDev
                                                bridgeIP:bridgeIP
                                           bridgeNetmask:bridgeNetmask
                                       DHCPEntriesRanges:DHCPRangeEntriesArray
                                        DHCPEntriesHosts:DHCPHostEntriesArray
                                          networkEnabled:networkActive
                                              STPEnabled:bridgeSTP
                                             DHCPEnabled:DHCPEnabled];

            [_datasourceNetworks addObject:newNetwork];
        }

        [_tableViewNetworks reloadData];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }
}


#pragma mark -
#pragma mark Action

/*! add a network
    @param sender the sender of the action
*/
- (IBAction)addNetwork:(id)aSender
{
    var uuid            = [CPString UUID],
        ip              = [self generateIPForNewNetwork],
        ipStart         = ip.split(".")[0] + "." + ip.split(".")[1] + ".0.2",
        ipEnd           = ip.split(".")[0] + "." + ip.split(".")[1] + ".0.254",
        baseDHCPEntry   = [TNDHCPEntry DHCPRangeWithStartAddress:ipStart  endAddress:ipEnd],
        newNetwork      = [TNNetwork networkWithName:uuid
                                                UUID:uuid
                                          bridgeName:@"br" + Math.round((Math.random() * 42000))
                                         bridgeDelay:@"0"
                                   bridgeForwardMode:@"nat"
                                 bridgeForwardDevice:@"eth0"
                                            bridgeIP:ip
                                       bridgeNetmask:@"255.255.0.0"
                                   DHCPEntriesRanges:[baseDHCPEntry]
                                    DHCPEntriesHosts:[CPArray array]
                                      networkEnabled:NO
                                          STPEnabled:NO
                                         DHCPEnabled:YES];

    [_datasourceNetworks addObject:newNetwork];
    [_tableViewNetworks reloadData];

    var index = [_datasourceNetworks indexOfObject:newNetwork];
    [_tableViewNetworks selectRowIndexes:[CPIndexSet indexSetWithIndex:index] byExtendingSelection:NO];

    [self defineNetworkXML];
    [self editNetwork:nil];

}

/*! delete a network
    @param sender the sender of the action
*/
- (IBAction)delNetwork:(id)aSender
{
    [self delNetwork];
}

/*! open network edition panel
    @param sender the sender of the action
*/
- (IBAction)editNetwork:(id)aSender
{
    if (![self currentEntityHasPermission:@"network_define"])
        return;

    var selectedIndex   = [[_tableViewNetworks selectedRowIndexes] firstIndex];

    if (selectedIndex != -1)
    {
        var networkObject = [_datasourceNetworks objectAtIndex:selectedIndex];

        if ([networkObject isNetworkEnabled])
        {
            [TNAlert showAlertWithMessage:@"Error" informative:@"You can't edit a running network"];
            return;
        }

        [networkController setNetwork:networkObject];
        [networkController showWindow:aSender];
    }
}

/*! define a network
    @param sender the sender of the action
*/
- (IBAction)defineNetworkXML:(id)aSender
{
    [self defineNetworkXML];
}

/*! activate a network
    @param sender the sender of the action
*/
- (IBAction)activateNetwork:(id)aSender
{
    [self activateNetwork];
}

/*! deactivate a network
    @param sender the sender of the action
*/
- (IBAction)deactivateNetwork:(id)aSender
{
    [self deactivateNetwork];
}


#pragma mark -
#pragma mark XMPP Controls

/*! ask hypervisor to define a network. It will indefine it before.
*/
- (void)defineNetworkXML
{
    var selectedIndex   = [[_tableViewNetworks selectedRowIndexes] firstIndex];

    if (selectedIndex == -1)
        return

    var networkObject   = [_datasourceNetworks objectAtIndex:selectedIndex];

    if ([networkObject isNetworkEnabled])
    {
        [CPAlert alertWithTitle:@"Error" message:@"You can't update a running network" style:CPCriticalAlertStyle];
        return
    }

    var stanza = [TNStropheStanza iqWithType:@"get"];

    [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorNetwork}];
    [stanza addChildWithName:@"archipel" andAttributes:{
        "action": TNArchipelTypeHypervisorNetworkUndefine,
        "uuid": [networkObject UUID]}];

    [self sendStanza:stanza andRegisterSelector:@selector(_didNetworkUndefinBeforeDefining:)];

}

/*! if hypervisor sucessfullty deactivate the network. it will then define it
    @param aStanza TNStropheStanza containing the answer
    @return NO to unregister selector
*/
- (BOOL)_didNetworkUndefinBeforeDefining:(TNStropheStanza)aStanza
{
    var uid             = [[[TNStropheIMClient defaultClient] connection] getUniqueId],
        defineStanza    = [self generateXMLNetworkStanzaWithUniqueID:uid];

    [self sendStanza:defineStanza andRegisterSelector:@selector(_didDefineNetwork:) withSpecificID:uid];

    return NO;
}

/*! compute if hypervisor has defined the network
    @param aStanza TNStropheStanza containing the answer
    @return NO to unregister selector
*/
- (BOOL)_didDefineNetwork:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Network" message:@"Network has been defined"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! ask hypervisor to activate a network
*/
- (void)activateNetwork
{
    var selectedIndexes = [_tableViewNetworks selectedRowIndexes],
        objects         = [_datasourceNetworks objectsAtIndexes:selectedIndexes];

    for (var i = 0; i < [objects count]; i++)
    {
        var networkObject   = [objects objectAtIndex:i],
            stanza          = [TNStropheStanza iqWithType:@"set"];

        if (![networkObject isNetworkEnabled])
        {
            [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorNetwork}];
            [stanza addChildWithName:@"archipel" andAttributes:{
                "xmlns": TNArchipelTypeHypervisorNetwork,
                "action": TNArchipelTypeHypervisorNetworkCreate,
                "uuid": [networkObject UUID]}];

            [self sendStanza:stanza andRegisterSelector:@selector(_didNetworkStatusChange:)];
            [_tableViewNetworks deselectAll];
        }
    }
}

/*! ask hypervisor to deactivate a network. but before ask use if he is sure with an alert
*/
- (void)deactivateNetwork
{
    var alert = [TNAlert alertWithMessage:@"Deactivate Network"
                                informative:@"Are you sure you want to deactivate this network ? Virtual machines that are in this network will loose connectivity."
                                 target:self
                                 actions:[["Deactivate", @selector(_performDeactivateNetwork:)], ["Cancel", nil]]];

    [alert runModal];

}

/*! ask hypervisor to deactivate a network
*/
- (void)_performDeactivateNetwork:(id)someUserInfo
{
    var selectedIndexes = [_tableViewNetworks selectedRowIndexes],
        objects         = [_datasourceNetworks objectsAtIndexes:selectedIndexes];

    for (var i = 0; i < [objects count]; i++)
    {
        var networkObject   = [objects objectAtIndex:i],
            stanza          = [TNStropheStanza iqWithType:@"set"];

        if ([networkObject isNetworkEnabled])
        {
            [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorNetwork}];
            [stanza addChildWithName:@"archipel" andAttributes:{
                "xmlns": TNArchipelTypeHypervisorNetwork,
                "action": TNArchipelTypeHypervisorNetworkDestroy,
                "uuid" : [networkObject UUID]}];

            [self sendStanza:stanza andRegisterSelector:@selector(_didNetworkStatusChange:)];
            [_tableViewNetworks deselectAll];
        }
    }
}

/*! compute the answer of hypervisor after activating/deactivating a network
    @param aStanza TNStropheStanza containing the answer
    @return NO to unregister selector
*/
- (BOOL)_didNetworkStatusChange:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Network" message:@"Network status has changed"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

/*! ask hypervisor to undefine a network. but before ask use if he is sure with an alert
*/
- (void)delNetwork
{
    var alert = [TNAlert alertWithMessage:@"Delete Network"
                                informative:@"Are you sure you want to destroy this network ? Virtual machines that are in this network will loose connectivity."
                                 target:self
                                 actions:[["Delete", @selector(performDelNetwork:)], ["Cancel", nil]]];

    [alert runModal];
}

/*! ask hypervisor to undefine a network.
*/
- (void)performDelNetwork:(id)someUserInfo
{
    var selectedIndexes = [_tableViewNetworks selectedRowIndexes],
        objects         = [_datasourceNetworks objectsAtIndexes:selectedIndexes];

    for (var i = 0; i < [objects count]; i++)
    {
        var networkObject   = [objects objectAtIndex:i];

        if ([networkObject isNetworkEnabled])
        {
            [CPAlert alertWithTitle:@"Error" message:@"You can't update a running network" style:CPCriticalAlertStyle];
            return
        }

        var stanza    = [TNStropheStanza iqWithType:@"get"];

        [stanza addChildWithName:@"query" andAttributes:{"xmlns": TNArchipelTypeHypervisorNetwork}];
        [stanza addChildWithName:@"archipel" andAttributes:{
            "xmlns": TNArchipelTypeHypervisorNetwork,
            "action": TNArchipelTypeHypervisorNetworkUndefine,
            "uuid": [networkObject UUID]}];

        [self sendStanza:stanza andRegisterSelector:@selector(_didDelNetwork:)];
    }
}

/*! compute if hypervisor has undefined the network
    @param aStanza TNStropheStanza containing the answer
    @return NO to unregister selector
*/
- (BOOL)_didDelNetwork:(TNStropheStanza)aStanza
{
    if ([aStanza type] == @"result")
    {
        [[TNGrowlCenter defaultCenter] pushNotificationWithTitle:@"Network" message:@"Network has been removed"];
    }
    else
    {
        [self handleIqErrorFromStanza:aStanza];
    }

    return NO;
}

@end
