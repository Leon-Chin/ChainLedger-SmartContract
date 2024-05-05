// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract UserManagement {
    struct UserInfo {
        string name;
        string avatar;
        string description;
    }

    mapping(address => UserInfo) public users;

    event UserInfoUpdated(
        address user,
        string name,
        string avatar,
        string description
    );

    function registerUser(
        string calldata _name,
        string calldata _avatar,
        string calldata _description
    ) public {
        require(
            bytes(users[msg.sender].name).length == 0,
            "User already registered."
        );
        users[msg.sender] = UserInfo(_name, _avatar, _description);
        emit UserInfoUpdated(msg.sender, _name, _avatar, _description);
    }

    function defaultRegisterUserWithAddress(address _user) external {
        UserInfo storage user = users[_user];
        if (bytes(user.name).length == 0) {
            user.name = "User";
            user.avatar = "";
            user.description = "";
            emit UserInfoUpdated(_user, "User", "", "");
        }
    }

    function updateUser(
        string calldata _name,
        string calldata _avatar,
        string calldata _description
    ) external {
        require(
            bytes(users[msg.sender].name).length != 0,
            "User not registered."
        );
        users[msg.sender] = UserInfo(_name, _avatar, _description);
        emit UserInfoUpdated(msg.sender, _name, _avatar, _description);
    }

    function getUserInfo(address _user) public view returns (UserInfo memory) {
        return users[_user];
    }
}
