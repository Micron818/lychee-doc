import React, { useEffect, useState } from 'react';
import { PageContainer, ProTable, ProDescriptions } from '@ant-design/pro-components';
import { Alert, Button, Modal, Space, Tooltip, Typography, Tag } from 'antd';
import { WarningOutlined } from '@ant-design/icons';

/**
 * FO Detail Page Skeleton
 * 目的：作为 FO 明细页的基础骨架，
 * 让规则、UI 提示、按钮状态都有明确落点。
 */

const FoDetailPage: React.FC = () => {
  const [loading, setLoading] = useState(false);
  const [fo, setFo] = useState<any>(null);
  const [lines, setLines] = useState<any[]>([]);

  useEffect(() => {
    // TODO: 调用 API 取得 FO Header + Lines
    // setFo(...)
    // setLines(...)
  }, []);

  const handleConfirm = () => {
    if (fo?.needDueDateConfirm) {
      Modal.confirm({
        title: '交期确认',
        content: '是否确认以最早交期作为排产基准？',
        onOk: submitConfirm,
      });
      return;
    }
    submitConfirm();
  };

  const submitConfirm = () => {
    // TODO: 调用 Confirm API
  };

  return (
    <PageContainer loading={loading}>
      {/* ===== FO Header 风险提示 ===== */}
      {fo?.sourceSoCount > 1 && (
        <Alert
          type="info"
          showIcon
          message={`本 FO 汇总自 ${fo.sourceSoCount} 笔 SO`}
          style={{ marginBottom: 12 }}
        />
      )}

      {fo?.hasMultipleDueDates && (
        <Alert
          type="warning"
          showIcon
          message="存在多组交期，请留意排产策略"
          style={{ marginBottom: 12 }}
        />
      )}

      {/* ===== FO Header 基本信息 ===== */}
      <ProDescriptions
        column={4}
        bordered
        dataSource={fo}
        columns={[
          { title: 'FO No', dataIndex: 'foNo' },
          { title: '状态', dataIndex: 'status' },
          { title: '客户', dataIndex: 'customerName' },
          { title: '需求日期', dataIndex: 'dueDate' },
        ]}
      />

      {/* ===== 操作按钮 ===== */}
      <Space style={{ margin: '16px 0' }}>
        <Tooltip title={!fo?.canConfirm ? fo?.confirmBlockReason : undefined}>
          <Button type="primary" disabled={!fo?.canConfirm} onClick={handleConfirm}>
            Confirm
          </Button>
        </Tooltip>
        <Button disabled={!fo?.canRunMrp}>执行 MRP</Button>
      </Space>

      {/* ===== FO Lines ===== */}
      <ProTable
        rowKey="id"
        search={false}
        options={false}
        dataSource={lines}
        columns={[
          { title: '行', dataIndex: 'lineNo', width: 60 },
          { title: '产品编码', dataIndex: 'itemCode' },
          { title: '产品名称', dataIndex: 'itemName' },
          {
            title: '数量',
            dataIndex: 'quantity',
            render: (value, record) => (
              <Space direction="vertical" size={0}>
                <span>{value}</span>
                {record.mergedFromSoCount > 1 && (
                  <Typography.Text type="secondary">
                    已合并自 {record.mergedFromSoCount} 笔 SO
                  </Typography.Text>
                )}
              </Space>
            ),
          },
          { title: '单位', dataIndex: 'uom', width: 80 },
          {
            title: '需求日期',
            dataIndex: 'dueDate',
            render: (value, record) => (
              <Space>
                {value}
                {record.hasDueDateRisk && (
                  <Tooltip title={record.dueDateRiskMessage}>
                    <WarningOutlined style={{ color: '#faad14' }} />
                  </Tooltip>
                )}
              </Space>
            ),
          },
          {
            title: '来源 SO',
            dataIndex: 'sourceSos',
            render: (sos: string[]) => (
              <Tooltip title={sos?.join(', ')}>
                {sos?.slice(0, 2).join(', ')}
                {sos?.length > 2 && ` +${sos.length - 2}`}
              </Tooltip>
            ),
          },
        ]}
        expandable={{
          expandedRowRender: (record) => (
            <ProTable
              rowKey="id"
              search={false}
              options={false}
              pagination={false}
              dataSource={record.soDetails}
              columns={[
                { title: 'SO No', dataIndex: 'soNo' },
                { title: 'SO 行', dataIndex: 'soLineNo' },
                { title: '数量', dataIndex: 'qty' },
                { title: '交期', dataIndex: 'dueDate' },
              ]}
            />
          ),
        }}
      />

      <SoSelectDrawer
        open={drawerOpen}
        foId={fo.id}
        onClose={() => setDrawerOpen(false)}
        onConfirm={handleSoImport}
      />

    </PageContainer>
  );
};

export default FoDetailPage;


