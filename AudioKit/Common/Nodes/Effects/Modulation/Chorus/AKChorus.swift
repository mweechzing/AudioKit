//
//  AKChorus.swift
//  AudioKit
//
//  Created by Shane Dunne
//  Copyright © 2018 AudioKit. All rights reserved.
//

/// Stereo Chorus
///
open class AKChorus: AKNode, AKToggleable, AKComponent, AKInput {
    public typealias AKAudioUnitType = AKChorusAudioUnit
    /// Four letter unique description of the node
    public static let ComponentDescription = AudioComponentDescription(effect: "chrs")

    // MARK: - Properties

    private var internalAU: AKAudioUnitType?
    private var token: AUParameterObserverToken?

    public static let frequencyRange = Double(kAKChorus_MinFrequency) ... Double(kAKChorus_MaxFrequency)
    public static let depthRange = Double(kAKChorus_MinDepth) ... Double(kAKChorus_MaxDepth)
    public static let feedbackRange = Double(kAKChorus_MinFeedback) ... Double(kAKChorus_MaxFeedback)
    public static let dryWetMixRange = Double(kAKChorus_MinDryWetMix) ... Double(kAKChorus_MaxDryWetMix)

    public static let defaultFrequency = Double(kAKChorus_DefaultFrequency)
    public static let defaultDepth = Double(kAKChorus_DefaultDepth)
    public static let defaultFeedback = Double(kAKChorus_DefaultFeedback)
    public static let defaultDryWetMix = Double(kAKChorus_DefaultDryWetMix)

    fileprivate var frequencyParameter: AUParameter?
    fileprivate var depthParameter: AUParameter?
    fileprivate var feedbackParameter: AUParameter?
    fileprivate var dryWetMixParameter: AUParameter?

    /// Ramp Time represents the speed at which parameters are allowed to change
    @objc open dynamic var rampTime: Double = AKSettings.rampTime {
        willSet {
            internalAU?.rampTime = newValue
        }
    }

    /// Modulation Frequency (Hz)
    @objc open dynamic var frequency: Double = defaultFrequency {
        willSet {
            if frequency == newValue {
                return
            }

            if internalAU?.isSetUp ?? false {
                if token != nil && frequencyParameter != nil {
                    frequencyParameter?.setValue(Float(newValue), originator: token!)
                    return
                }
            }

            internalAU?.frequency = newValue
        }
    }

    /// Modulation Depth (fraction)
    @objc open dynamic var depth: Double = defaultDepth {
        willSet {
            if depth == newValue {
                return
            }

            if internalAU?.isSetUp ?? false {
                if token != nil && depthParameter != nil {
                    depthParameter?.setValue(Float(newValue), originator: token!)
                    return
                }
            }

            internalAU?.depth = newValue
        }
    }

    /// Feedback (fraction)
    @objc open dynamic var feedback: Double = defaultFeedback {
        willSet {
            if feedback == newValue {
                return
            }

            if internalAU?.isSetUp ?? false {
                if token != nil && feedbackParameter != nil {
                    feedbackParameter?.setValue(Float(newValue), originator: token!)
                    return
                }
            }

            internalAU?.feedback = newValue
        }
    }

    /// Dry Wet Mix (fraction)
    @objc open dynamic var dryWetMix: Double = defaultDryWetMix {
        willSet {
            if dryWetMix == newValue {
                return
            }

            if internalAU?.isSetUp ?? false {
                if token != nil && dryWetMixParameter != nil {
                    dryWetMixParameter?.setValue(Float(newValue), originator: token!)
                    return
                }
            }

            internalAU?.dryWetMix = newValue
        }
    }

    /// Tells whether the node is processing (ie. started, playing, or active)
    @objc open dynamic var isStarted: Bool {
        return internalAU?.isPlaying ?? false
    }

    // MARK: - Initialization

    /// Initialize this chorus node
    ///
    /// - Parameters:
    ///   - input: AKNode whose output will be processed
    ///   - frequency: modulation frequency Hz
    ///   - depth: depth of modulation (fraction)
    ///   - feedback: feedback fraction
    ///   - dryWetMix: fraction of wet signal in mix
    ///
    @objc public init(
        _ input: AKNode? = nil,
        frequency: Double = defaultFrequency,
        depth: Double = defaultDepth,
        feedback: Double = defaultFeedback,
        dryWetMix: Double = defaultDryWetMix) {

        self.frequency = frequency
        self.depth = depth
        self.feedback = feedback
        self.dryWetMix = dryWetMix

        _Self.register()

        super.init()
        AVAudioUnit._instantiate(with: _Self.ComponentDescription) { [weak self] avAudioUnit in
            guard let strongSelf = self else {
                AKLog("Error: self is nil")
                return
            }
            strongSelf.avAudioNode = avAudioUnit
            strongSelf.internalAU = avAudioUnit.auAudioUnit as? AKAudioUnitType

            input?.connect(to: self!)
        }

        guard let tree = internalAU?.parameterTree else {
            AKLog("Parameter Tree Failed")
            return
        }

        frequencyParameter = tree["frequency"]
        depthParameter = tree["depth"]
        feedbackParameter = tree["feedback"]
        dryWetMixParameter = tree["dryWetMix"]

        token = tree.token(byAddingParameterObserver: { [weak self] _, _ in

            guard let _ = self else {
                AKLog("Unable to create strong reference to self")
                return
            } // Replace _ with strongSelf if needed
            DispatchQueue.main.async {
                // This node does not change its own values so we won't add any
                // value observing, but if you need to, this is where that goes.
            }
        })
        internalAU?.setParameterImmediately(.frequency, value: frequency)
        internalAU?.setParameterImmediately(.depth, value: depth)
        internalAU?.setParameterImmediately(.feedback, value: feedback)
        internalAU?.setParameterImmediately(.dryWetMix, value: dryWetMix)
    }

    // MARK: - Control

    /// Function to start, play, or activate the node, all do the same thing
    @objc open func start() {
        AKLog("start() \(isStopped)")
    }

    /// Function to stop or bypass the node, both are equivalent
    @objc open func stop() {
        AKLog("stop() \(isPlaying)")
    }
}
