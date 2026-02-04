#!/usr/bin/env swift
import Foundation

typealias CGSConnectionID = UInt32

@_silgen_name("CGSMainConnectionID")
func CGSMainConnectionID() -> CGSConnectionID

@_silgen_name("CGSCreateLoginSession")
func CGSCreateLoginSession(_ ownerPID: inout pid_t, _ outConnectionID: inout CGSConnectionID) -> Int32

var pid: pid_t = 0
var cid: CGSConnectionID = 0
let result = CGSCreateLoginSession(&pid, &cid)
exit(result)
