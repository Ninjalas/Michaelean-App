// MOCK DATA — sample Home content for the frontend prototype.
// School News holds real posts from SMCL's official Facebook page
// (facebook.com/mec.smcl), text and photos as the school published them,
// supplied for this preview (assets/school_posts.docx). Their dates are
// estimates except the volleyball post's; the hackathon post is dated newest
// on purpose so it's Home's featured story (decided 2026-10-26). Department news likewise holds
// real posts from the Computer Science Society's page, posted as the
// Department of Computer Studies (assets/computer_science_society_posts.docx;
// dates estimated). Every other post is invented; its images are real SMCL
// posters used for illustration only.

import '../models/feed.dart';

const _css = 'Computer Science Society';
const _dcs = 'Department of Computer Studies';
const _cssLogo = 'assets/images/profiles/css_profile.jpg';
const _smcl = "Saint Michael's College of Laguna";
const _smclEmblem = 'assets/images/SMCL_Emblem.png';

List<Post> mockPosts(DateTime now) => [
      // Announcements — everyone
      Post(
        id: 'a1',
        kind: PostKind.announcement,
        title: 'Midterm examination schedule posted',
        body: 'Sample announcement. The midterm examination schedule is now '
            'available. Check with your instructors for room assignments.',
        source: "Registrar's Office",
        publishedAt: now.subtract(const Duration(hours: 2)),
      ),
      Post(
        id: 'a2',
        kind: PostKind.announcement,
        title: 'Updated campus map for the new semester',
        body: 'Sample announcement. Use the updated map to find halls, the '
            'library commons, and the conference center.',
        source: 'Campus Services',
        imageAsset: 'assets/images/SMCL_MAP.png',
        publishedAt: now.subtract(const Duration(days: 1, hours: 3)),
      ),
      Post(
        id: 'a3',
        kind: PostKind.announcement,
        title: 'Reminder: wear your school ID on campus',
        body: 'Sample announcement. Please keep your school ID visible while on '
            'campus.',
        source: 'Office of Student Affairs',
        publishedAt: now.subtract(const Duration(days: 2)),
      ),
      Post(
        id: 'a4',
        kind: PostKind.announcement,
        title: 'Enrollment for next semester opens soon',
        body: 'Sample announcement. Watch for the enrollment schedule for your '
            'school and year level.',
        source: "Registrar's Office",
        publishedAt: now.subtract(const Duration(days: 3, hours: 2)),
      ),

      // School news — everyone: real posts from SMCL's Facebook page, newest first.
      Post(
        id: 'n-hackathon',
        kind: PostKind.schoolNews,
        title: 'MICHAELEAN INNOVATION AND EXCELLENCE',
        body:
            'Congratulations to **Angelic Innovators** for securing **1st Runner-Up** and receiving a **PhP 50,000 cash prize** at the **iAcademy 24-Hour Hackathon**, held on October 6–7, 2026, at the iACADEMY Nexus Campus in Makati City! 🎉\n\n'
            '**Special Awards**:\n- **1st Functional Prototype**\n- **Best in Live Demonstration**\n- **Best in Real-World Application**\n**The Angelic Innovators**:\n• **Nicolas Emanuel Santos** – BSCS, 3rd Year\n• **John Gabriel Galino** – ACT, 2nd Year\n• **Josh Ariad P. Dilla** – ACT, 2nd Year\n• **King Robby I. Flores** – Senior High School, Grade 11\n• **Don Gabriel M. Dolatre** – Senior High School, Grade 11\n\n'
            'With their adviser, **Dr. Anna Liza A. Ramos**, the team demonstrated creativity, collaboration, and a commitment to developing innovative solutions.\n\n'
            'The event was organized with the support of the Polish Investment and Trade Agency (PAIH), the Embassy of Poland in Manila, Spiderhook Inc., and iACADEMY.\n\n'
            'The entire SMCL Family is proud of all of you! 💙\n\n'
            '#SMCLAmazingAngels #OurHomeandPride #ChampioningExcellence',
        source: _smcl,
        sourceImage: _smclEmblem,
        imageAsset: 'assets/images/news/hackathon_angelic_innovators.jpg',
        publishedAt: DateTime(2026, 10, 21, 19, 0),
      ),
      Post(
        id: 'n-volleyball',
        kind: PostKind.schoolNews,
        title: 'RISING TO THE OCCASION',
        body:
            'Congratulations to the **ARCHANGELS VOLLEYBALL TEAM** for their outstanding performance at the **Brent Volleyball Pocket Tournament 2026**!\n\n'
            '**Division 2 High School Boys — 1st Runner-Up** 🏆\n\n'
            '**Division 2 High School Girls — 1st Runner-Up** 🏆\n\n'
            'This achievement reflects the teams’ dedication, teamwork, and determination on the court. Congratulations, Archangels, on this well-earned finish!\n\n'
            'The entire SMCL Family is proud of all of you! 💙 🏐\n\n'
            '#SMCLAmazingAngels #OurHomeandPride #ChampioningExcellence #MichaeleanPride',
        source: _smcl,
        sourceImage: _smclEmblem,
        imageAsset: 'assets/images/news/volleyball_archangels.jpg',
        publishedAt: DateTime(2026, 10, 16, 15, 0),
      ),
      Post(
        id: 'n-pitlc',
        kind: PostKind.schoolNews,
        title: 'BEYOND THE COLD, MICHAELEANS FOUND THEIR FIRE IN BAGUIO.',
        body:
            'Three Michaeleans journeyed to Baguio carrying more than just their names — they carried SMCL, CALABARZON, and the courage to take their place on the national stage. They returned home with stories worth telling, experiences worth remembering, and achievements worth celebrating.\n\n'
            '**Read their story. Find their fire. Maybe, ignite yours**. ✨\n\n'
            '#BIDABayani\n#BeTheChange\n#PITLC2026',
        source: _smcl,
        sourceImage: _smclEmblem,
        imageAsset: 'assets/images/news/pitlc_baguio.jpg',
        publishedAt: DateTime(2026, 10, 9, 18, 0),
      ),
      Post(
        id: 'n-limaco-keynote',
        kind: PostKind.schoolNews,
        title: 'KEYNOTE SPEAKER: 7TH MILAGROS L. LIMACO MEMORIAL PAPER PRESENTATION',
        body:
            'We are honored to introduce **Dr. Agnes L. Llamasares-Castillo** as the keynote speaker for the **7th Milagros L. Limaco Memorial Paper Presentation**.\n\n'
            'With her extensive experience in research and academe, she brings valuable expertise and insights that will enrich this celebration of research, innovation, and academic excellence.\n\n'
            '**Agnes L. Llamasares-Castillo, Ph.D, RPh**\n\n'
            'Professor, University of Santo Tomas, Manila, Philippines\n\n'
            'Researcher, Research Center for the Natural and Applied Sciences, UST\n\n'
            'Research Awardee – FACES of PACOP (2025)\n\n'
            'NRCP Achievement Awardee – Division IV, Pharmaceutical Sciences (2025)\n\n'
            '**October 9, 2026** 📅\n**8:00 AM–4:00 PM** 🕗\n**Saint Theodore Hall** 📍\n\n'
            'We look forward to an inspiring exchange of knowledge and ideas as we continue to advance research excellence through innovation and collaboration.\n\n'
            '#SMCLAmazingAngels #OurHomeandPride #ChampioningExcellence #7thMilagrosLLimacoMemorialPaperPresentation #LevellingUpOurLegacy',
        source: _smcl,
        sourceImage: _smclEmblem,
        imageAsset: 'assets/images/news/limaco_keynote_speaker.jpg',
        publishedAt: DateTime(2026, 10, 5, 16, 0),
      ),
      Post(
        id: 'n-psychometricians',
        kind: PostKind.schoolNews,
        title: 'MICHAELEAN EXCELLENCE IN PSYCHOLOGY',
        body:
            'Congratulations to our new **Michaelean Registered Psychometricians**! 🎉\n\n'
            'Our **Psychology graduates** achieved an outstanding **100**% **passing rate** in the **September 2026 Psychometrician Licensure Examination (PmLE**), surpassing the **91.72**% **national passing rate**.\n\n'
            'Continue to shine in your profession and uphold the values of excellence, compassion, and service. You are our pride! 💙 🧠\n\n'
            '#SMCLAmazingAngels #OurHomeandPride #ChampioningExcellence #MichaeleanPride #PMLE2026 #RegisteredPsychometricians',
        source: _smcl,
        sourceImage: _smclEmblem,
        imageAsset: 'assets/images/news/psychometricians_just_in.jpg',
        extraImages: ['assets/images/news/psychometricians_100.jpg'],
        publishedAt: DateTime(2026, 10, 3, 9, 0),
      ),
      Post(
        id: 'n-limaco',
        kind: PostKind.schoolNews,
        title: '7TH MILAGROS L. LIMACO MEMORIAL PAPER PRESENTATION',
        body:
            'Saint Michael’s College of Laguna, through the **Research Center**, presents the **7th Milagros L. Limaco Memorial Paper Presentation**.\n\n'
            'Guided by the theme, “**Levelling Up Our Legacy: Empowering Global Research Excellence through Innovation and Collaboration**,” the event highlights the importance of research in generating new knowledge, fostering innovation, and creating meaningful solutions for communities and society.\n\n'
            'Join us as we bring together researchers and members of the academic community to share ideas, present meaningful research, and celebrate excellence in research and innovation. 💡 📚\n\n'
            '**October 9, 2026** 📅\n**8:00 AM–4:00 PM** 🕗\n**Saint Theodore Hall** 📍\n\n'
            'Let us come together to celebrate research that informs, inspires, and helps shape a better future. ✨\n\n'
            '#SMCLAmazingAngels #OurHomeandPride #ChampioningExcellence #7thMilagrosLLimacoMemorialPaperPresentation #LevellingUpOurLegacy',
        source: _smcl,
        sourceImage: _smclEmblem,
        imageAsset: 'assets/images/news/limaco_paper_presentation.jpg',
        publishedAt: DateTime(2026, 9, 30, 17, 0),
      ),
      Post(
        id: 'n-michaelmas',
        kind: PostKind.schoolNews,
        title: 'MICHAELMAS 2026: FEAST OF SAINT MICHAEL THE ARCHANGEL',
        body:
            'The entire Michaelean Community joins the Christendom in honoring the Archangels on their feast day, September 29, 2026, through the celebration of Michaelmas at Saint Theodore Hall. The celebration will be presided over by Msgr. Mario Rafael Castillo.\n\n'
            'In observance of the feast, September 30, 2026 will be a self-directed day. There will be no onsite business transactions, and entry to the school campus will be restricted.\n\n'
            'May the intercession of Saint Michael the Archangel continue to guide, protect, and inspire the entire Michaelean Community.\n\n'
            'Happy Feast of Saint Michael the Archangel! 💙 ✨',
        source: _smcl,
        sourceImage: _smclEmblem,
        imageAsset: 'assets/images/news/michaelmas_2026.jpg',
        publishedAt: DateTime(2026, 9, 26, 10, 0),
      ),

      // For You — matched by audience
      Post(
        id: 'o1',
        kind: PostKind.organizationNews,
        title: "Venue change for Friday's general meeting",
        body: "Sample post. Friday's meeting moves to Milagros Limaco Hall. "
            'Same time.',
        source: _css,
        sourceImage: _cssLogo,
        publishedAt: now.subtract(const Duration(hours: 1)),
        urgent: true,
        audience: _css,
      ),
      Post(
        id: 'o2',
        kind: PostKind.organizationNews,
        title: 'Recap: hands-on Git and collaboration seminar',
        body: 'Sample post. Members practiced committing, pushing, and working '
            'together on a shared repository.',
        source: _css,
        sourceImage: _cssLogo,
        imageAsset: 'assets/images/events/css_commitevent.jpg',
        publishedAt: now.subtract(const Duration(days: 1)),
        audience: _css,
      ),
      // Department news: real posts from the Computer Science Society's page, newest first.
      Post(
        id: 'd-huefest',
        kind: PostKind.departmentNews,
        title: 'HUEFEST: THE PLAYLIST OF OUR GENERATION',
        body:
            '**The playlist is set. The colors are ready. And now, it’s time to make some memories, Michaeleans**! 💙 ❤️ 🤍\n\n'
            'Get ready to sing your heart out, dance like nobody’s watching, and meet the people who might just become your favorite part of this school year. From the first beat to the last song, HUEFest is where every vibe, every color, and every Michaelean comes together. 🎧\n\n'
            'Because every generation has a playlist — and this one is ours. 🎵\n\n'
            '**So, Michaeleans, are you ready to press PLAY**? ▶️ 🔥\n\n'
            '#TEDMeetandMingle2026\n#HUEFest2026ThePlaylistOfOurGeneration',
        source: _dcs,
        audience: _dcs,
        imageAsset: 'assets/images/dcs/huefest_2026.jpg',
        publishedAt: DateTime(2026, 10, 14, 19, 0),
      ),
      Post(
        id: 'd-innovation-contest',
        kind: PostKind.departmentNews,
        title: 'LEVEL UP YOUR IDEAS, CREATE YOUR FUTURE!',
        body:
            'Are you tired of doomscrolling and losing track of time? Instead of fighting against technology, how can we use it to our advantage? 🤔 💡\n\n'
            'As part of **SBMIT Fest 2026**, the **Department of Computer Studies (DCS**) brings you **The DCS Innovation Contest**! We are challenging all Junior High School and Senior High School students to think outside the box and present creative, tech-based solutions to combat digital fatigue and boost student productivity.\n\n'
            'Got an idea for a cool app, study tool, or smart hack? Gather your crew and turn those ideas into reality!\n\n'
            '**HOW TO JOIN**: 👥\n\n'
            '1. **Team Up**: Form a group of **3 members** from your school (JHS or SHS category).\n\n'
            '2. **Brainstorm & Design**: Answer the innovation question and prepare a title, brief description, process flow, and a **1-minute prototype video** (paper sketches, Canva mock-ups, or clickable slides are all welcome—no complex coding required!).\n\n'
            '3. **Submit**: Upload your details and entry on or before the deadline.\n\n'
            '**WHAT’S IN IT FOR YOU**? 🏆\n• **Cash Prize**: ₱3,000.00 for the winning team!\n• **Recognition**: Showcased during SBMIT Fest and featured on the official Computer Science Society Facebook page.\n• **Impact**: Help your fellow students reclaim their focus and level up their study habits!\n\n'
            '**SUBMISSION DEADLINE**: October 23, 2026 | 11:59 PM 📅\n\n'
            '**WINNER ANNOUNCEMENT**: October 28, 2026 (SBMIT Fest) 📣\n\n'
            '**SUBMIT YOUR ENTRY HERE**: https://forms.gle/wwnVtanCvenRSeg67 🔗\n\n'
            '**For more details about submission mechanics and general guidelines, click here**: https://bit.ly/4xvM3N5 📄\n\n'
            'Free registration. Bring your best ideas—let’s innovate together! 🔥 🎮\n\n'
            '#SBMITFest2026\n#DCSInnovationContest\n#LevelUpYourIdeas\n#DepartmentofComputerStudies\n#SMCL',
        source: _dcs,
        audience: _dcs,
        imageAsset: 'assets/images/dcs/dcs_innovation_contest_1.jpg',
        extraImages: ['assets/images/dcs/dcs_innovation_contest_2.jpg', 'assets/images/dcs/dcs_innovation_contest_3.jpg', 'assets/images/dcs/dcs_innovation_contest_4.jpg'],
        publishedAt: DateTime(2026, 10, 12, 17, 0),
      ),
      Post(
        id: 'd-hackathon-look',
        kind: PostKind.departmentNews,
        title: 'LOOK: ANGELIC INNOVATORS ARE 1ST RUNNER-UP AT THE 24-HOUR HACKATHON',
        body:
            'LOOK | Saint Michael’s College of Laguna’s Angelic Innovators secured the 1st Runner-Up title and a ₱50,000 prize at the 5th Annual Poland-Philippines IT Business Summit: 24-Hour Hackathon 2026, held from October 6 to 7 at iACADEMY in Makati City.\n\n'
            'The team, composed of Nicolas Emanuel R. Santos, Josh Ariad P. Dilla, John Gabriel P. Galino, Don Gabriel M. Dolate, and King Robby I. Flores, represented SMCL in a 24-hour competition challenging student innovators to develop technological solutions for real-world urban challenges.\n\n'
            'Organized through a Poland-Philippines collaboration, the summit brought together technology, business, and young Filipino innovators under one platform.\n\n'
            'The event also highlighted and welcomed the President of the Republic of Poland Karol Nawrocki who personally greeted the participants and witnessed their project building firsthand.\n\n'
            'Angelic Innovators claimed the 1st Runner-up title, just behind iACADEMY’s Lakad Kinetic Development, which bagged the ₱100,000 Grand Prize Champion title.\n\n'
            'This achievement highlighted the contribution of SMCL’s Computer Science Department with three of its students among the five members guiding the team throughout the competition.\n\n'
            'With their 24-hour challenge ending in a spot among the competition’s top teams, Angelic Innovators proudly carried SMCL’s name and the Biñan pride onto the hackathon stage.\n\n'
            'Congratulations, Angelic Innovators!\nWritten by: Don Gabriel Dolatre\n\n'
            'Photos from: @prezydent_pl IG, iAcademy, and Don Gabriel Dolatre',
        source: _dcs,
        audience: _dcs,
        imageAsset: 'assets/images/dcs/hackathon_byjc_1.jpg',
        extraImages: ['assets/images/dcs/hackathon_byjc_2.jpg', 'assets/images/dcs/hackathon_byjc_3.jpg', 'assets/images/dcs/hackathon_byjc_4.jpg'],
        publishedAt: DateTime(2026, 10, 10, 20, 0),
      ),
      Post(
        id: 'd-lyca-mscs',
        kind: PostKind.departmentNews,
        title: 'A PROUD MOMENT TO CELEBRATE!',
        body:
            'The Computer Studies Society proudly extends its warmest congratulations to our esteemed faculty member, Ma’am Aliza Lyca Gonzales-Lacson, on her well-deserved achievement of earning her Master of Science in Computer Science (MSCS)! 🎓 💻\n\n'
            'On behalf of the Computer Studies Society, we are immensely proud of you, Ma’am Lyca! Your achievement is not only a personal milestone but also an inspiration to your students, colleagues, and the entire Computer Studies community. 💙\n\n'
            '**Congratulations, Ma’am Aliza Lyca Gonzales-Lacson**! 👩‍🏫 🎓 ✨\n\n'
            '#CongratulationsMaamLyca\n#MasterOfScienceInComputerScience\n#ComputerStudiesSociety\n#MichaeleanInnovators',
        source: _dcs,
        audience: _dcs,
        imageAsset: 'assets/images/dcs/dcs_lyca_mscs.jpg',
        publishedAt: DateTime(2026, 10, 2, 18, 0),
      ),
      // Schedule and classroom changes (teacher Home)
      Post(
        id: 'c1',
        kind: PostKind.scheduleChange,
        title: 'CS 302 moves to Milagros Limaco 207 on Thursday',
        body: 'Sample change. Thursday\'s CS 302 session will be held in '
            'Milagros Limaco 207 instead of the usual room.',
        source: _dcs,
        publishedAt: now.subtract(const Duration(hours: 7)),
        audience: _dcs,
      ),
      // Not for Nicolas — other affiliations. Must be filtered out.
      Post(
        id: 'x1',
        kind: PostKind.departmentNews,
        title: 'Clinical duty schedule released',
        body: 'Sample post for nursing students.',
        source: 'School of Nursing',
        publishedAt: now.subtract(const Duration(hours: 3)),
        audience: 'SON',
      ),
      Post(
        id: 'x2',
        kind: PostKind.organizationNews,
        title: 'Dance Company auditions',
        body: 'Sample post for Dance Company members.',
        source: 'Dance Company',
        publishedAt: now.subtract(const Duration(hours: 4)),
        urgent: true,
        audience: 'Dance Company',
      ),
    ];

/// Student tasks besides clearance ones (those come from the clearance data).
const mockTasks = [
  PendingTask(
    id: 't2',
    title: 'Event requirements',
    detail: '3 of 6 cleared. Attend 3 more required events.',
    status: TaskStatus.actionRequired,
    route: '/life/events',
  ),
];

const mockTeacherTasks = [
  PendingTask(
    id: 't3',
    title: 'Review schedule change',
    detail: 'CS 302 on Thursday: confirm the new room.',
    status: TaskStatus.actionRequired,
    route: '/life/classes/cs302-3a',
  ),
];

const mockUpcomingEventCount = 2;

List<AppNotification> mockTeacherNotifications(DateTime now) => [
      AppNotification(
        id: 'm5',
        kind: NotificationKind.schedule,
        title: 'Schedule change: CS 302 moves to Milagros Limaco 207 on Thursday',
        time: now.subtract(const Duration(hours: 7)),
        postId: 'c1',
      ),
      AppNotification(
        id: 'm6',
        kind: NotificationKind.schedule,
        title: 'Department assembly moved to Friday afternoon',
        time: now.subtract(const Duration(hours: 9)),
        postId: 'e2',
      ),
      AppNotification(
        id: 'm7',
        kind: NotificationKind.attendance,
        title: 'CS 301 attendance is waiting to be finalized',
        time: now.subtract(const Duration(hours: 11)),
        route: '/life/classes/cs301-2a',
      ),
    ];

List<AppNotification> mockNotifications(DateTime now) => [
      AppNotification(
        id: 'm1',
        kind: NotificationKind.organization,
        title: "Computer Science Society: Venue change for Friday's meeting",
        time: now.subtract(const Duration(hours: 1)),
        postId: 'o1',
        urgent: true, // the post is marked URGENT
      ),
      AppNotification(
        id: 'm2',
        kind: NotificationKind.announcement,
        title: 'New announcement: Midterm examination schedule posted',
        time: now.subtract(const Duration(hours: 2)),
        postId: 'a1',
      ),
      AppNotification(
        id: 'm3',
        kind: NotificationKind.clearance,
        title: 'Library clearance needs correction',
        time: now.subtract(const Duration(hours: 6)),
        route: '/life/clearance/lib',
      ),
      AppNotification(
        id: 'm4',
        kind: NotificationKind.organization,
        title: 'Recap posted: hands-on Git and collaboration seminar',
        time: now.subtract(const Duration(days: 1)),
        postId: 'o2',
        read: true, // seen yesterday
      ),
    ];
