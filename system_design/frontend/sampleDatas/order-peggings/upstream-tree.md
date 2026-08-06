- request
```shell
curl --location 'http://localhost:9000/api/v1/common/order-peggings/upstream-tree?orderType=MRP_RESULT&orderId=603'
```

- response
```json
{
    "code": 200,
    "success": true,
    "message": "操作成功",
    "data": {
        "currentNodeId": "MRP_RESULT-603",
        "upstreamTree": {
            "nodeId": "MRP_RESULT-603",
            "orderType": "MRP_RESULT",
            "orderId": 603,
            "orderNo": "RUN-20260404-100045",
            "materialId": 316,
            "materialCode": "D00453-A01",
            "materialName": "D00453-A WHT/12-0643TPX LOGO +F100-2热熔胶+热压材料 3#",
            "peggedQuantity": 100.000000,
            "orderTotalQuantity": 100.000000,
            "status": "PENDING",
            "relationType": "TARGET",
            "children": [
                {
                    "nodeId": "FACTORY_ORDER-52",
                    "orderType": "FACTORY_ORDER",
                    "orderId": 52,
                    "orderNo": "FO-1",
                    "materialId": 316,
                    "materialCode": "D00453-A01",
                    "materialName": "D00453-A WHT/12-0643TPX LOGO +F100-2热熔胶+热压材料 3#",
                    "peggedQuantity": 100.000000,
                    "orderTotalQuantity": 100.000000,
                    "status": "CONFIRMED",
                    "relationType": "DEMAND",
                    "children": [
                        {
                            "nodeId": "SALES_ORDER-9",
                            "orderType": "SALES_ORDER",
                            "orderId": 9,
                            "orderNo": "SO-20260309-001",
                            "materialId": 316,
                            "materialCode": "D00453-A01",
                            "materialName": "D00453-A WHT/12-0643TPX LOGO +F100-2热熔胶+热压材料 3#",
                            "peggedQuantity": 100.000000,
                            "orderTotalQuantity": 1000.000000,
                            "status": "CONFIRMED",
                            "relationType": "DEMAND",
                            "children": []
                        }
                    ]
                }
            ]
        },
        "downstreamTree": null
    },
    "timestamp": "2026-04-06T11:47:51.9994609"
}
```