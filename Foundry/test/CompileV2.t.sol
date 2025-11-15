// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/V2/PropertyRegistry.sol";
import "../src/V2/TenantPassportV2.sol";
import "../src/V2/RentalAgreementFactory.sol";

contract CompileV2Test {
    PropertyRegistry public registry;
    TenantPassportV2 public passport;
    RentalAgreementFactory public factory;
}
