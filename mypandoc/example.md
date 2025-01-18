

# Summary

This deployment consists of the EMPI Identity Service and EMPI Consumer.  The identity resolution uses an external provider Verato.  The api documentation is provided separately.  The customizations mentioned in the patient registration section are in this project.  The core Verato implementation is a module within `empi-core`.

\pagebreak
# Architecture

TODO: need to add an overal description of services.  Only mention deviations from norms and reference core documentation

# Patient Registration Logic

## Handling the Source Identifiers and Aggregate ID

Because Contexture deals with mrn re-use we are using Verato's overlay detection to alter the default `aggregate_id` behavior.  Patient registration will use the fields from `nexus::PatientDemographics` along with `Contexture Master Feed List`.  See the section on OID resolution.

1. register patient with Verato
   * lookup "Verato Source" from the "master feed list"
   * "Native Id" constructed as: "[Verato Source]::MRN"
2. if an overlay is detected append an increment
   * format: "[Verato Source]::MRN::[index]"
3. The response will include:
   * `aggregateId`: `[Verato Source]::[MRN]` or `[Verato Source]::[MRN]::[index]` 
   * `empiId`: the value of "Verato's Link Id"
   * `patientIdRoot`: OID
   * `patientIdExt`: MRN

## Custom Properties

This is done at patient upsert

# Custom OID Resolution

TODO: Describe the OID resolution logic and data structures

\pagebreak

# Deploy Configuration

## Empi Service Configuration File

```yaml
apiUrl: https://cust0033-dev.verato-connect.com
apiUrlIp: 104.16.96.56:443
# credentials used for basic authentication on top of
# mutual tls
basicUsername: contexture.umpi.cust0033-dev.2023.04
basicPw: "..."
# name of the filenames for mutual tls within the "config" folder
# on s3
veratoKeyLoc: verato.key
veratoPemLoc: verato.pem
clientConfig:
  maxOverlayRetries: 20000
  # this is where the verato responses are archived
  veratoArchivedResponses:
    locationType: s3
    bucket: "[env]-contexture-empisvc"
    subFolder: "archive-output"
  # the current state of polled identity updates
  notificationsState:
    location:
      type: s3
      location: "[env]-contexture-empisvc"
    path: "/config/notifications-search-state.json"
  # oid to verato source name resolution 
  # provided mappings by Contexture
  veratoSourceMappings:
    location:
      type: s3
      location: "dev-contexture-empisvc"
    path: "/config/verato_source_mappings.csv"
```

## ECR Information

Need to test this out TODO
```txt
Harsh Kharate 
October 26, 2023 at 3:37 AM
Edited


161674638527.dkr.ecr.us-east-1.amazonaws.com/ninjacat/empi-test
161674638527.dkr.ecr.us-east-1.amazonaws.com/ninjacat/empi-prod

@Manideep Senagapalli As per our discussion over teams we have created 2 ECR  repos in AWS ROOT Account. permissions for the repos have been updated . These should be available in 4 AWS accounts mentioned below: 


Ohip : 392240231723
sdhl : 870745327828
Contexture: 014355562867
wyfi: 851153337270
CC: @Mohan Gadige  
```

# Source Mapping

High level view of matching Verato source name and facility codes.

```{.plantuml caption="This is an image, created by **PlantUML**." width=100%}
@startuml

object VeratoSourceMappingRow {

  postTransformedFacilityCode
  veratoSourceName
  facilityOid
}


object ContextureNativeId {
  postTransformedFacilityCode

  mrn

  Option<Index>
}

object AggregateId


note left of AggregateId
facilityCode::mrn::index
end note

object VeratoRegisterPatient {

  veratoSourceName
}

map ExtendedPatientMapping {
  facilityOid => id.RootOid
  mrn => id.extension
}

object RegisteredPatient {
  empiId
  aggregateId
  patientIdExt
  patientIdRoot
}

frame "VeratoSourceMapping" {
  object postTransformedFacilityCode
  object facilityOid
  postTransformedFacilityCode "1"--"1" facilityOid
}

note right of VeratoRegisterPatient
veratoSourceName 
extracted from
the matched facility 
code and oid pair
end note




ExtendedPatientMapping ---> "VeratoSourceMapping"
"VeratoSourceMapping" ----> VeratoSourceMappingRow
VeratoSourceMappingRow ---> ContextureNativeId
VeratoSourceMappingRow ---> VeratoRegisterPatient

VeratoRegisterPatient ---> RegisteredPatient
ContextureNativeId --> AggregateId
AggregateId ---> RegisteredPatient



@enduml
```

# Delete Identity

## Logic Flow Diagram

```{.plantuml caption="This is an image, created by **PlantUML**." width=100%}
@startuml
start
:DeleteIdentityRequest;
if (does nativeId exist) then (Yes)
    if (does nativeId with increment exists?) then (Yes)
        :CannotDeleteError;
        stop
    else (No)
        :MarkDeleted;
        stop
    endif
else (No)
    :UpsertIdentity;
    :MarkDeleted;
    stop
endif
@enduml
```

# NativeID

## Original Native ID Logic Text

Original notes given before the project started:

```text
Nexus/InterChange will ping PReg API with Demo + OID + MRN
    EMPI Service (PtReg) - Demo + OID + MRN + VeratoSrcID::MRN 
      Invoke Verato API
        200 - Success
        Conflict
           Demo + OID + MRN + VeratoSrcID::MRN::1 
            Conflict
               Demo + OID + MRN + VeratoSrcID::MRN::2
               200 - Success
    Response to Nexus/InterChange team - OID + MRN + VeratoSrcID::MRN::2 + EMPIID (LinkID)
```

## NativeID Logic Flow Diagram

See <https://crashedmind.github.io/PlantUMLHitchhikersGuide/> on usage

```{.plantuml caption="This is an image, created by **PlantUML**." width=100%}
@startuml
start
:postIdentity;

while (is Overlay?) is (Yes)
    :demographicsQuery;
    if (is Match?) then (Yes)
        :Success;
        stop
    else (No)
        :Increment Index;
        :Retry postIdentity;
    endif
endwhile (No)
:Success;
stop
@enduml
```

# Terminology

## `nativeId`
Verato's source id.  Otherwise known as the MRN.  Sometimes used interchangibly in the documentation

## `linkId`
Verato's empi id

