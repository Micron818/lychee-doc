/**
 * =============================================
 * FO / SO 汇总模块 TypeScript DTO 定义
 * 目的：
 * - 作为前后端数据契约（Contract）
 * - 支撑 FO Detail Page / SO Select Drawer
 * - 明确规则判断结果的返回结构（RuleResult）
 * =============================================
 */

/* =============================
 * 基础枚举
 * ============================= */

export type FoStatus = 'DRAFT' | 'CONFIRMED' | 'RELEASED' | 'CLOSED';

export type RiskLevel = 'NONE' | 'WARNING' | 'BLOCK';

/* =============================
 * Rule Result（规则判断统一结构）
 * ============================= */

export interface RuleResult {
  /** 是否允许当前操作 */
  allowed: boolean;

  /** 风险等级 */
  level: RiskLevel;

  /** 阻挡或风险原因（给 UI tooltip / alert 使用） */
  message?: string;

  /** 需要人工确认（如交期策略） */
  needConfirm?: boolean;
}

/* =============================
 * SO Line DTO（SO 汇入来源）
 * ============================= */

export interface SoLineDTO {
  id: string;

  soNo: string;
  soLineNo: number;

  customerId: string;
  customerName: string;

  itemId: string;
  itemCode: string;
  itemName: string;

  qty: number;
  uom: string;

  dueDate: string; // YYYY-MM-DD

  /** 已转 FO 数量 */
  transferredQty: number;

  /** 剩余可转数量 */
  availableQty: number;

  /** 是否允许汇入当前 FO */
  mergeRule: RuleResult;
}

/* =============================
 * FO Line DTO（FO 需求明细）
 * ============================= */

export interface FoLineDTO {
  id: string;
  lineNo: number;

  itemId: string;
  itemCode: string;
  itemName: string;

  quantity: number;
  uom: string;

  dueDate: string;

  /** 来源 SO 汇总 */
  sourceSoNos: string[];

  /** 合并自几笔 SO Line */
  mergedFromSoCount: number;

  /** SO 追溯明细（expandable 使用） */
  soDetails: Array<{
    soNo: string;
    soLineNo: number;
    qty: number;
    dueDate: string;
  }>;

  /** 行级规则（交期风险 / 数量风险等） */
  lineRule?: RuleResult;
}

/* =============================
 * FO Header DTO
 * ============================= */

export interface FoDTO {
  id: string;
  foNo: string;

  status: FoStatus;

  customerId: string;
  customerName: string;

  plantId: string;

  dueDate: string;

  /** 来源 SO 数量 */
  sourceSoCount: number;

  /** 是否存在多组交期 */
  hasMultipleDueDates: boolean;

  /** 是否包含部分转单 */
  hasPartialTransfer: boolean;

  /** 是否允许 Confirm */
  confirmRule: RuleResult;

  /** 是否允许执行 MRP */
  mrpRule: RuleResult;
}

/* =============================
 * FO Detail API 返回结构
 * ============================= */

export interface FoDetailResponse {
  fo: FoDTO;
  lines: FoLineDTO[];
}

/* =============================
 * SO Select Drawer API 返回结构
 * ============================= */

export interface SoSelectableResponse {
  foId: string;
  soLines: SoLineDTO[];
}

/* =============================
 * 设计原则说明（给后端 & 前端）
 * ============================= */

/**
 * 1️⃣ 所有业务规则 → RuleResult
 *    - 前端不自行判断规则
 *    - 只根据 allowed / level / message / needConfirm 渲染 UI
 *
 * 2️⃣ UI 与规则解耦
 *    - 禁用：allowed = false
 *    - 警告：level = WARNING
 *    - 弹窗确认：needConfirm = true
 *
 * 3️⃣ DTO 可复用
 *    - 同一套结构可用于：
 *      SO → FO、FO → MRP、FO → MO
 */
