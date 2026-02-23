# Errors

Allure will only care about the type of `content` and `meta` during the calls of `Allure:Node` and `Allure:NodeWorkspace`
<br>So you can only get the following errors:

## Bad Types in :Node or :ZeroNode
> *Content passed to Allure:Node()(HERE)() has an unusual type: ? (table expected)*
> <br>*Content passed to Allure:ZeroNode()(HERE)() has an unusual type: ? (table expected)*
> <br>*Metadata passed to Allure:Node()()(HERE) has an unusual type: ? (table expected)*
> <br>*Metadata passed to Allure:ZeroNode()()(HERE) has an unusual type: ? (table expected)*

You have passed a type different from "table" as `content` or `metadata` respectively.

## Bad Types in :NodeWorkspace
> *Content passed to Allure:NodeWorkspace()(HERE)() has an unusual type: ? (table expected)*
> <br>*Metadata passed to Allure:NodeWorkspace()()(HERE) has an unusual type: ? (table expected)*

You have passed a type different from "table" as `content` or `metadata` respectively.