// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//  从当前路径引入其他合约
import { HelloWorld } from "./HelloWorld.sol";

contract HelloWorldFactory {

    // 定义新的合约  
    HelloWorld helloWorld;

    HelloWorld[] hwArray;

    //  创建新合约的函数
    function createHelloWorld() public {

        //  初始化新的合约
        helloWorld = new HelloWorld();
        //  新合约添加到数组中
        hwArray.push(helloWorld);
    }

    //  根据数组下标获取合约
    function getHelloWorldByIndex(uint256 _inedx) public view returns (HelloWorld) {
        return hwArray[_inedx];
    }


    //  调用 合约中设置结构体的方法
    function callSetHelloWorldFromFactory(uint256 _index, string memory newString, uint256 _id) public {
        hwArray[_index].setHelloWorld(newString, _id);
    }

    //  调用合约中结构体输出方法
    function callSayHelloFromFactory(uint256 _index, uint256 _id) public view returns (string memory) {
        return hwArray[_index].sayHello(_id);
    }
}