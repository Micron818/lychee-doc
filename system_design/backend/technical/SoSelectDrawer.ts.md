import React, { useEffect, useState } from 'react';
import { Drawer, Button, Space, Tooltip, Tag } from 'antd';
import { ProTable } from '@ant-design/pro-components';
import { WarningOutlined } from '@ant-design/icons';

/**
 * SO Select Drawer
 * 用途：将多个 SO / SO Line 汇入同一张 FO
 * 特点：
 * - 禁用不可汇总 SO
 * - 风险 SO 可选但有提示
 * - 前端不判断规则，仅呈现后端结果
 */

export interface SoSelectDrawerProps {
  open: boolean;
  foId: string;
  onClose: () => void;
  onConfirm: (selectedSoLines: any[]) => void;
}

const SoSelectDrawer: React.FC<SoSelectDrawerProps> = ({
  open,
  foId,
  onClose,
  onConfirm,
}) => {
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState<any[]>([]);
  const [selectedRowKeys, setSelectedRowKeys] = useState<React.Key[]>([]);
  const [selectedRows, setSelectedRows] = useState<any[]>([]);

  useEffect(() => {
    if (open) {
      // TODO: 调用 API，取得可汇入的 SO / SO Line 列表
      // setData(...)
    }
  }, [open]);

  return (
    <Drawer
      title="选择 SO 汇入 FO"
      width={900}
      open={open}
      onClose={onClose}
      destroyOnClose
      footer={
        <Space style={{ float: 'right' }}>
          <Button onClick={onClose}>取消</Button>
          <Button
            type="primary"
            disabled={selectedRows.length === 0}
            onClick={() => onConfirm(selectedRows)}
          >
            汇入所选 SO（{selectedRows.length}）
          </Button>
        </Space>
      }
    >
      <ProTable
        rowKey="id"
        loading={loading}
        search={false}
        options={false}
        dataSource={data}
        rowSelection={{
          selectedRowKeys,
          onChange: (keys, rows) => {
            setSelectedRowKeys(keys);
            setSelectedRows(rows);
          },
          getCheckboxProps: (record) => ({
            disabled: !record.canMerge,
          }),
        }}
        columns={[
          { title: 'SO No', dataIndex: 'soNo', width: 140 },
          { title: 'SO 行', dataIndex: 'soLineNo', width: 80 },
          { title: '客户', dataIndex: 'customerName' },
          { title: '产品', dataIndex: 'itemCode' },
          { title: '数量', dataIndex: 'qty' },
          { title: '交期', dataIndex: 'dueDate' },
          {
            title: '状态',
            dataIndex: 'mergeStatus',
            render: (_, record) => {
              if (!record.canMerge) {
                return (
                  <Tooltip title={record.mergeBlockReason}>
                    <Tag color="default">不可汇总</Tag>
                  </Tooltip>
                );
              }
              if (record.hasRisk) {
                return (
                  <Tooltip title={record.riskMessage}>
                    <Tag color="warning">
                      风险 <WarningOutlined />
                    </Tag>
                  </Tooltip>
                );
              }
              return <Tag color="green">可汇总</Tag>;
            },
          },
        ]}
      />
    </Drawer>
  );
};

export default SoSelectDrawer;
