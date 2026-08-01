import { defineConfig, type DefaultTheme } from 'vitepress'

/**
 * Lychee Doc — VitePress
 *
 * 内容目录保持 user_training/zh 与 user_training/vi 镜像约定。
 * 站点默认语言为中文；越南文入口挂在导航，待内容就绪后再升级为完整 locales 镜像。
 */
function userTrainingSidebar(): DefaultTheme.SidebarItem[] {
  return [
    {
      text: '总纲',
      collapsed: false,
      items: [
        { text: '训练首页', link: '/user_training/' },
        { text: '写作约定', link: '/user_training/00-conventions' },
        { text: '术语表', link: '/user_training/glossary' },
      ],
    },
    {
      text: '入门',
      collapsed: false,
      items: [
        { text: '系统入门', link: '/user_training/zh/01-getting-started/01-system-overview' },
        { text: '导出中心', link: '/user_training/zh/01-getting-started/02-export-center' },
      ],
    },
    {
      text: '整体流程',
      collapsed: false,
      items: [
        { text: '本节索引', link: '/user_training/zh/00-overview/' },
        { text: 'OV-01 系统流程地图', link: '/user_training/zh/00-overview/01-system-process-map' },
        { text: 'OV-02 销货闭环', link: '/user_training/zh/00-overview/02-order-to-cash' },
        { text: 'OV-03 采购闭环', link: '/user_training/zh/00-overview/03-procure-to-pay' },
        { text: 'OV-04 计划生产', link: '/user_training/zh/00-overview/04-plan-to-produce' },
        { text: 'OV-05 关账协作', link: '/user_training/zh/00-overview/05-period-close-collaboration' },
      ],
    },
    {
      text: '角色手册',
      collapsed: false,
      items: [
        { text: '系统管理员', link: '/user_training/zh/02-roles/role-admin' },
        { text: '主数据维护', link: '/user_training/zh/02-roles/role-master-data' },
        { text: '销售', link: '/user_training/zh/02-roles/role-sales' },
        { text: '采购', link: '/user_training/zh/02-roles/role-procurement' },
        { text: '仓储', link: '/user_training/zh/02-roles/role-warehouse' },
        { text: '生产计划', link: '/user_training/zh/02-roles/role-production' },
        { text: '财务', link: '/user_training/zh/02-roles/role-finance' },
      ],
    },
    {
      text: '流程剧本',
      collapsed: false,
      items: [
        { text: 'PB-01 主数据就绪', link: '/user_training/zh/03-process-playbooks/PB-01-master-data-ready' },
        { text: 'PB-02 销售出货', link: '/user_training/zh/03-process-playbooks/PB-02-sales-to-delivery' },
        { text: 'PB-03 采购入库与应付', link: '/user_training/zh/03-process-playbooks/PB-03-procure-to-pay' },
        { text: 'PB-04 计划到生产回馈', link: '/user_training/zh/03-process-playbooks/PB-04-mrp-to-production' },
        { text: 'PB-05 库存与财务关账', link: '/user_training/zh/03-process-playbooks/PB-05-period-close' },
        { text: 'PB-06 导出与打印', link: '/user_training/zh/03-process-playbooks/PB-06-export-and-print' },
      ],
    },
    {
      text: '模块速查',
      collapsed: true,
      items: [
        { text: '速查索引', link: '/user_training/zh/04-module-quickref/' },
        { text: 'ADM 系统管理', link: '/user_training/zh/04-module-quickref/adm' },
        { text: 'BASIS 基础资料', link: '/user_training/zh/04-module-quickref/basis' },
        { text: 'MM 物料', link: '/user_training/zh/04-module-quickref/mm' },
        { text: 'SD 销售', link: '/user_training/zh/04-module-quickref/sd' },
        { text: 'SCM 采购', link: '/user_training/zh/04-module-quickref/scm' },
        { text: 'WM 仓储', link: '/user_training/zh/04-module-quickref/wm' },
        { text: 'PP 生产计划', link: '/user_training/zh/04-module-quickref/pp' },
        { text: 'FI 财务', link: '/user_training/zh/04-module-quickref/fi' },
        { text: 'REPORT 报表', link: '/user_training/zh/04-module-quickref/report' },
      ],
    },
    {
      text: '运维开通',
      collapsed: true,
      items: [
        { text: '菜单与权限', link: '/user_training/zh/05-admin-ops/01-menu-and-permission' },
        { text: '导出上线检查清单', link: '/user_training/zh/05-admin-ops/02-export-go-live-checklist' },
      ],
    },
    {
      text: '越南文',
      collapsed: true,
      items: [
        { text: '进度说明', link: '/user_training/vi/' },
      ],
    },
  ]
}

function systemDesignSidebar(): DefaultTheme.SidebarItem[] {
  return [
    {
      text: '报表与导出',
      collapsed: false,
      items: [
        { text: '规划总览', link: '/system_design/report/' },
        { text: '01 技术选型评估', link: '/system_design/report/01-技术选型评估' },
        { text: '02 导出框架总体设计', link: '/system_design/report/02-导出框架总体设计' },
        { text: '03 供应商 Excel 导出', link: '/system_design/report/03-示例-供应商Excel导出' },
        { text: '04 订购单打印表单', link: '/system_design/report/04-示例-订购单打印表单' },
      ],
    },
  ]
}

export default defineConfig({
  title: 'Lychee ERP 文档',
  description: 'Lychee ERP 用户训练与系统设计文档',
  lang: 'zh-CN',
  cleanUrls: true,
  ignoreDeadLinks: true,
  lastUpdated: true,
  // 仓库根 README 仅供 Git；站点目录首页必须使用 index.md（README.md 不会映射为 /path/）
  srcExclude: ['README.md', '**/assets/**'],

  head: [['meta', { name: 'theme-color', content: '#1a5f4a' }]],

  themeConfig: {
    logo: undefined,
    siteTitle: 'Lychee Doc',

    nav: [
      { text: '首页', link: '/' },
      { text: '用户训练', link: '/user_training/', activeMatch: '/user_training/' },
      { text: '系统设计', link: '/system_design/report/', activeMatch: '/system_design/' },
      { text: '术语表', link: '/user_training/glossary' },
      { text: 'Tiếng Việt', link: '/user_training/vi/' },
    ],

    sidebar: {
      '/user_training/': userTrainingSidebar(),
      '/system_design/': systemDesignSidebar(),
    },

    search: {
      provider: 'local',
      options: {
        locales: {
          root: {
            translations: {
              button: { buttonText: '搜索', buttonAriaLabel: '搜索文档' },
              modal: {
                noResultsText: '没有找到相关结果',
                resetButtonTitle: '清除查询',
                footer: {
                  selectText: '选择',
                  navigateText: '切换',
                  closeText: '关闭',
                },
              },
            },
          },
        },
      },
    },

    outline: {
      label: '本页目录',
      level: [2, 3],
    },

    docFooter: {
      prev: '上一页',
      next: '下一页',
    },

    lastUpdated: {
      text: '最后更新',
      formatOptions: { dateStyle: 'medium', timeStyle: 'short' },
    },

    returnToTopLabel: '回到顶部',
    sidebarMenuLabel: '菜单',
    darkModeSwitchLabel: '主题',
    lightModeSwitchTitle: '切换到浅色',
    darkModeSwitchTitle: '切换到深色',

    socialLinks: [],
  },
})
