- request
```shell
curl --location 'http://localhost:9000/api/v1/common/order-peggings/downstream-tree?orderType=MRP_RESULT&orderId=603'
```

- response
```json
{
    "code": 200,
    "success": true,
    "message": "操作成功",
    "data": {
        "currentNodeId": "MRP_RESULT-603",
        "upstreamTree": null,
        "downstreamTree": {
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
                    "nodeId": "MRP_RESULT-604",
                    "orderType": "MRP_RESULT",
                    "orderId": 604,
                    "orderNo": "RUN-20260404-100045",
                    "materialId": 355,
                    "materialCode": "I00175-B03",
                    "materialName": "I00175-B  WHT/BLK/13-0751TPG  LOGO + C305长纤  6#-7#",
                    "peggedQuantity": 3.833295,
                    "orderTotalQuantity": 10.000000,
                    "status": "PENDING",
                    "relationType": "SUPPLY",
                    "children": []
                },
                {
                    "nodeId": "MRP_RESULT-605",
                    "orderType": "MRP_RESULT",
                    "orderId": 605,
                    "orderNo": "RUN-20260404-100045",
                    "materialId": 42,
                    "materialCode": "PC01",
                    "materialName": "PVC原料",
                    "peggedQuantity": 5.750000,
                    "orderTotalQuantity": 20.000000,
                    "status": "PENDING",
                    "relationType": "SUPPLY",
                    "children": [
                        {
                            "nodeId": "MRP_RESULT-606",
                            "orderType": "MRP_RESULT",
                            "orderId": 606,
                            "orderNo": "RUN-20260404-100045",
                            "materialId": 36,
                            "materialCode": "PR-G",
                            "materialName": "PR-G粉",
                            "peggedQuantity": 12.721231,
                            "orderTotalQuantity": 13.000000,
                            "status": "PENDING",
                            "relationType": "SUPPLY",
                            "children": []
                        },
                        {
                            "nodeId": "MRP_RESULT-607",
                            "orderType": "MRP_RESULT",
                            "orderId": 607,
                            "orderNo": "RUN-20260404-100045",
                            "materialId": 37,
                            "materialCode": "DHIN",
                            "materialName": "DHIN 油",
                            "peggedQuantity": 9.159290,
                            "orderTotalQuantity": 10.000000,
                            "status": "PENDING",
                            "relationType": "SUPPLY",
                            "children": []
                        },
                        {
                            "nodeId": "MRP_RESULT-608",
                            "orderType": "MRP_RESULT",
                            "orderId": 608,
                            "orderNo": "RUN-20260404-100045",
                            "materialId": 38,
                            "materialCode": "GS-296",
                            "materialName": "GS-296安定剂",
                            "peggedQuantity": 0.508852,
                            "orderTotalQuantity": 1.000000,
                            "status": "PENDING",
                            "relationType": "SUPPLY",
                            "children": []
                        },
                        {
                            "nodeId": "MRP_RESULT-609",
                            "orderType": "MRP_RESULT",
                            "orderId": 609,
                            "orderNo": "RUN-20260404-100045",
                            "materialId": 39,
                            "materialCode": "GL-22",
                            "materialName": "GL-22大豆油",
                            "peggedQuantity": 0.254426,
                            "orderTotalQuantity": 1.000000,
                            "status": "PENDING",
                            "relationType": "SUPPLY",
                            "children": []
                        },
                        {
                            "nodeId": "MRP_RESULT-610",
                            "orderType": "MRP_RESULT",
                            "orderId": 610,
                            "orderNo": "RUN-20260404-100045",
                            "materialId": 40,
                            "materialCode": "MAX-700",
                            "materialName": "MAX-700降粘剂",
                            "peggedQuantity": 0.254426,
                            "orderTotalQuantity": 1.000000,
                            "status": "PENDING",
                            "relationType": "SUPPLY",
                            "children": []
                        },
                        {
                            "nodeId": "MRP_RESULT-611",
                            "orderType": "MRP_RESULT",
                            "orderId": 611,
                            "orderNo": "RUN-20260404-100045",
                            "materialId": 43,
                            "materialCode": "RW-K100",
                            "materialName": "K-100",
                            "peggedQuantity": 0.101775,
                            "orderTotalQuantity": 1.000000,
                            "status": "PENDING",
                            "relationType": "SUPPLY",
                            "children": []
                        }
                    ]
                }
            ]
        }
    },
    "timestamp": "2026-04-06T11:48:21.095578"
}
```