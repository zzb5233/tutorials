// SPDX-License-Identifier: Apache-2.0
/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

const bit<16> TYPE_IPV4 = 0x800;

/* IP protocols */
const bit<8> IP_PROTOCOLS_ICMP       =   1;
const bit<8> IP_PROTOCOLS_IGMP       =   2;
const bit<8> IP_PROTOCOLS_IPV4       =   4;
const bit<8> IP_PROTOCOLS_TCP        =   6;
const bit<8> IP_PROTOCOLS_UDP        =  17;
const bit<8> IP_PROTOCOLS_IPV6       =  41;
const bit<8> IP_PROTOCOLS_GRE        =  47;
const bit<8> IP_PROTOCOLS_IPSEC_ESP  =  50;
const bit<8> IP_PROTOCOLS_IPSEC_AH   =  51;
const bit<8> IP_PROTOCOLS_ICMPV6     =  58;
const bit<8> IP_PROTOCOLS_EIGRP      =  88;
const bit<8> IP_PROTOCOLS_OSPF       =  89;
const bit<8> IP_PROTOCOLS_PIM        = 103;
const bit<8> IP_PROTOCOLS_VRRP       = 112;


/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;
typedef bit<32> ip4Addr_t;

header ethernet_t {
    macAddr_t dstAddr;
    macAddr_t srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<6>    diffserv;
    bit<2>    ecn;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    ip4Addr_t srcAddr;
    ip4Addr_t dstAddr;
}

struct metadata {
}

struct headers {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

    state start {
        transition parse_ethernet;
    }

    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }
}


/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/

control MyVerifyChecksum(inout headers hdr, inout metadata meta) {
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {
    action drop() {
        mark_to_drop(standard_metadata);
    }

    action ipv4_forward(macAddr_t dstAddr, egressSpec_t port) {
        standard_metadata.egress_spec = port;
        hdr.ethernet.srcAddr = hdr.ethernet.dstAddr;
        hdr.ethernet.dstAddr = dstAddr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }

    /* Default Forwarding */
    action default_forwarding() {
        hdr.ipv4.diffserv = 0;
    }

    /* Expedited Forwarding */
    action expedited_forwarding() {
        hdr.ipv4.diffserv = 46;
    }

    /* Voice Admit */
    action voice_admit() {
        hdr.ipv4.diffserv = 44;
    }

    /* Assured Forwarding */
    /* Class 1 Low drop probability */
    action af_11() {
        hdr.ipv4.diffserv = 10;
    }

    /* Class 1 Med drop probability */
    action af_12() {
        hdr.ipv4.diffserv = 12;
    }

    /* Class 1 High drop probability */
    action af_13() {
        hdr.ipv4.diffserv = 14;
    }

    /* Class 2 Low drop probability */
    action af_21() {
        hdr.ipv4.diffserv = 18;
    }

    /* Class 2 Med drop probability */
    action af_22() {
        hdr.ipv4.diffserv = 20;
    }

    /* Class 2 High drop probability */
    action af_23() {
        hdr.ipv4.diffserv = 22;
    }

    /* Class 3 Low drop probability */
    action af_31() {
        hdr.ipv4.diffserv = 26;
    }

    /* Class 3 Med drop probability */
    action af_32() {
        hdr.ipv4.diffserv = 28;
    }

    /* Class 3 High drop probability */
    action af_33() {
        hdr.ipv4.diffserv = 30;
    }

    /* Class 4 Low drop probability */
    action af_41() {
        hdr.ipv4.diffserv = 34;
    }

    /* Class 4 Med drop probability */
    action af_42() {
        hdr.ipv4.diffserv = 36;
    }

    /* Class 4 High drop probability */
    action af_43() {
        hdr.ipv4.diffserv = 38;
    }

    table ipv4_lpm {
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        actions = {
            ipv4_forward;
            drop;
            NoAction;
        }
        size = 1024;
        default_action = NoAction();
    }

    apply {
        if (hdr.ipv4.isValid()) {
            if (hdr.ipv4.protocol == IP_PROTOCOLS_UDP) {
                expedited_forwarding();
            }
            else if (hdr.ipv4.protocol == IP_PROTOCOLS_TCP) {
                voice_admit();
            }
            ipv4_lpm.apply();
        }
    }
}

/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply {  }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
     apply {
        update_checksum(
            hdr.ipv4.isValid(),
            { hdr.ipv4.version,
              hdr.ipv4.ihl,
              hdr.ipv4.diffserv,
              hdr.ipv4.ecn,
              hdr.ipv4.totalLen,
              hdr.ipv4.identification,
              hdr.ipv4.flags,
              hdr.ipv4.fragOffset,
              hdr.ipv4.ttl,
              hdr.ipv4.protocol,
              hdr.ipv4.srcAddr,
              hdr.ipv4.dstAddr },
            hdr.ipv4.hdrChecksum,
            HashAlgorithm.csum16);
    }
}

/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
