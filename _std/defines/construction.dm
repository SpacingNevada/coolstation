//table defines
#define TABLE_DISASSEMBLE 0
#define TABLE_WEAKEN 1
#define TABLE_STRENGTHEN 2
#define TABLE_ADJUST 3
#define TABLE_LOCKPICK 4

//girder defines
#define GIRDER_DISASSEMBLE 0
#define GIRDER_UNSECURESUPPORT 1
#define GIRDER_REMOVESUPPORT 2
#define GIRDER_DISLODGE 3
#define GIRDER_REINFORCE 4
#define GIRDER_SECURE 5
#define GIRDER_PLATE 6

//wall construction defines
#define WALL_REMOVERERODS 0
#define WALL_REMOVESUPPORTLINES 1
#define WALL_SLICECOVER 3
#define WALL_REMOVESUPPORTRODS 4
#define WALL_PRYCOVER 5
#define WALL_PRYSHEATH 6
#define WALL_DETATCHSUPPORTRODS 7

//railing defines
#define RAILING_DISASSEMBLE 0
#define RAILING_UNFASTEN 1
#define RAILING_FASTEN 2

//deconstruction_flags

#define DECON_NONE 0
/// no reqs, just deconstruct!
#define DECON_SIMPLE (1<<0)
#define DECON_SCREWDRIVER (1<<1)
#define DECON_WRENCH (1<<2)
#define DECON_CROWBAR (1<<3)
#define DECON_WELDER (1<<4)
#define DECON_WIRECUTTERS (1<<5)
#define DECON_MULTITOOL (1<<6)
/// flag added to something that is player-built
#define DECON_BUILT (1<<7)
/// can only be deconstructed if access required is null
#define DECON_ACCESS (1<<8)
/// item will be saved by path instead of stored in the frame
#define DECON_DESTRUCT (1<<9)
