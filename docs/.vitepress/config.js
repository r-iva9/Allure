export default {
  base: '/Allure/',
  title: "Allure",
  // titleTemplate: ":title ...",
  description: "Reactive Framework of Frameworks for the Roblox Metaverse.",
  head: [["link", { rel: "icon", href: "/biglogo.svg" }]],

  themeConfig: {
      logo: "/biglogo.svg",

      search: {
          provider: "local"
      },

      footer: {
          message: 'Released under the MIT License.',
      },

      // https://vitepress.dev/reference/default-theme-config
      nav: [
          { text: "Home", link: "/" },
          { text: "Documentation", link: "/course/introduction/intro" },
          //{ text: "API", link: "/api/reactivity-core"},
      ],

      sidebar: {
          "/api/": [
              {
                  text: "API",
                  items: [
                      // { text: "name", link: "/api/reactivity-core" },
                  ]
              }
          ],

          "/course/": [
              {
                  text: "Introduction",
                  items: [
                      { text: "What is Allure?", link: "/course/introduction/intro" },
                      { text: "Getting Started", link: "/course/introduction/gettingstarted" }
                  ]
              },
              {
                  text: "AllureUI",
                  items: [
                    { text: "Garbage", link: "/course/AllureUI/garbage" },
                    {
                        text: "States",
                        items: [
                            { text: "State", link: "/course/AllureUI/States/State" },
                            { text: "Setter and Getter", link: "/course/AllureUI/States/SetGet" },
                            { text: "Updater and Deleter", link: "/course/AllureUI/States/UpdateDelete" },
                            { text: "Custom attributes", link: "/course/AllureUI/States/Custom" },
                        ]
                    },
                    {
                        text: "Amplified Tables",
                        items: [
                            { text: "Amplified Table", link: "/course/AllureUI/Amplifieds/Amplified" },
                            { text: "State Keys", link: "/course/AllureUI/Amplifieds/StateKeys" },
                            { text: "Unique Values", link: "/course/AllureUI/Amplifieds/UniqueValues" },
                            { text: "Setter and Getter", link: "/course/AllureUI/Amplifieds/SetGet" },
                        ]
                    },
                    {
                        text: "Mounting",
                        items: [
                            { text: "Mounting", link: "/course/AllureUI/Mounting/Mount" },
                            { text: "Children", link: "/course/AllureUI/Mounting/UniqueValues" },
                            { text: "Events", link: "/course/AllureUI/Mounting/Events" },
                        ]
                    }
                  ]
              },
              {
                  text: "AllureBundle",
                  items: [
                    { text: ":New", link: "/course/AllureBundle/New" },
                    { text: "Computed", link: "/course/AllureBundle/Computed" },
                    { text: "Effect", link: "/course/AllureBundle/Effect" },
                  ]
              }
          ],
      },

      socialLinks: [
          { icon: "github", link: "https://github.com/m-at1/Allure" }
      ]
  }
}