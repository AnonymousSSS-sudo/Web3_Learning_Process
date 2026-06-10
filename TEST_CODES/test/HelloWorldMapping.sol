// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
// comment: This is my first smart contract
contract HelloWorld {

    string strVar = "Hello World";

    struct Info {
        string phase;
        uint256 id;
        address addr;
    }

    Info[] infoArray;

    function sayHello(uint256 _id) external view  returns (string memory) {
        //  从 infoArray 中根据 id 查询到对应的结构体内容
        for (uint256 i = 0; i < infoArray.length; i++) {
            if (infoArray[i].id == _id) {
                return addInfo(infoArray[i].phase);
            }
        }
        return addInfo(strVar);
    }

    function setHelloWorld(string memory newString, uint256 _id) public {
        //  创建一个新的结构体
        Info memory info = Info(newString, _id, msg.sender);
        infoArray.push(info);
    } 

    function addInfo(string memory helloString) internal pure returns (string memory updatedString) {
        return string.concat(helloString, ", from Sean's first smart contract.");
    }
}