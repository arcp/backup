#!/usr/bin/env python
# coding:utf-8

import xml.sax
import os

vsdnurl = 'http://dev.vsdn.tv380.com/vlogservice.asmx/VLGetDeviceList?param=check@soooner.com'

SCS = '0'
SAS = '1'

LIVE = '0'
VOD = '1'
BOTH = '2'

# <sbs addr="117.34.12.25" sid="CT-3rd-SBS-xian-25" type="0">
#     <scs addr="116.55.232.40" sid="CT-3rd-kunming-40" svctype="2" op1="1" op2="29" province="云南" node="昆明"/>
# </sbs>

SCS_KEYS = ('addr', 'sid',  )
SBS_KEYS = ('addr', 'sid', 'key')

def to_dev(attrs, keys, **d) :
    for k in keys :
        d[k.encode('utf8')] = attrs.getValue(k).encode('utf8')
    return d

class DeviceList(xml.sax.handler.ContentHandler) :
    def __init__(self) :
        self.scslist = []
        self.saslist = []
        self.sbs_group = ''

    def startElement(self, name, attrs) :
        if name == 'scs' :
            self.scslist.append(to_dev(attrs, SCS_KEYS))
        elif name == 'sas' :
            self.saslist.append(to_dev(attrs, SCS_KEYS))
        elif name == 'sbs' :
            sbs = to_dev(attrs, SBS_KEYS)
            self.sbs_group = sbs['key']

    def endElement(self, name) :
        if name == 'sbs' :

            if len(self.scslist) > 0:
                name = "/home/" + os.getlogin() + "/ip/" + self.sbs_group + '.scs'
                file = open(name,  'w')
                for scs in self.scslist:
                    file.write(scs['addr'])
                    file.write("\n")
                file.close()
       
            if len(self.saslist) > 0:
                name = os.path.join("/home", os.getlogin(), "ip/") + self.sbs_group + '.sas'
                file = open(name,  'w')
                for sas in self.saslist:
                    file.write(sas['addr'])
                    file.write("\n")
                file.close()

            self.sbs_group = ''
            self.scslist = []
            self.saslist = []

def devicelist() :
    import urllib

    parser = xml.sax.make_parser()
    handler = DeviceList()
    parser.setContentHandler(handler)

    fp = urllib.urlopen(vsdnurl)
    if fp.code == 200:
        parser.parse(vsdnurl)
        return handler.scslist, handler.saslist, 
    else:
        raise Exception('device list url error')


if __name__ == '__main__' :
    import sys
    t,u= devicelist()
    #printResult(t, u, v)
