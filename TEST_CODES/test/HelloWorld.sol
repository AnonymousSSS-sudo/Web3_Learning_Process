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

    //  在合约中初始化键值对数据结构
    mapping(uint256 _id => Info info) infoMapping;

    function sayHello(uint256 _id) external view  returns (string memory) {
        //  从 键值对中获取到对应的 结构体 Info 元素
        if (infoMapping[_id].addr == address(0x0)) {
            //  未查询到对应结构体 （address 为空地址）
            return addInfo(strVar);
        } else {
            return addInfo(infoMapping[_id].phase);
        }
    }

    function setHelloWorld(string memory newString, uint256 _id) public {
        //  创建一个新的结构体
        Info memory info = Info(newString, _id, msg.sender);
        //  infoArray.push(info);
        //  在键值对中添加元素
        infoMapping[_id] = info;
    } 

    function addInfo(string memory helloString) internal pure returns (string memory updatedString) {
        return string.concat(helloString, ", from Sean's first smart contract.");
    }
}