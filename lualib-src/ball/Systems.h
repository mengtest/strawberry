#ifndef SYSTEMS_H
#define SYSTEMS_H

#include <systems/IndexSystem.h>
#include <systems\EventSystem.h>
#include <systems/JoinSystem.h>
#include <systems/LogSystem.h>
#include <systems/MapSystem.h>
#include <systems/MoveSystem.h>

namespace Chestnut {
	namespace Ball {
		class Systems {
		public:
			Systems();
			~Systems();

			auto GetIndexSystem()->RefCountedPtr<IndexSystem> const;
			auto GetJoinSystem()->RefCountedPtr<JoinSystem> const;
		private:
			RefCountedPtr<IndexSystem> _indexSystem;
			RefCountedPtr<JoinSystem> _joinSystem;
		};
	}
}

#endif // !SYSTEMS_H
